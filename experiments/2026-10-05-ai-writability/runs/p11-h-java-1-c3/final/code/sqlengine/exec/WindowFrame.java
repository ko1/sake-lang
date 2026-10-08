package sqlengine.exec;

import java.util.List;
import sqlengine.parse.Ast.BoundKind;
import sqlengine.parse.Ast.FrameBound;
import sqlengine.parse.Ast.FrameMode;
import sqlengine.parse.Ast.FrameSpec;
import sqlengine.parse.Ast.OrderTerm;
import sqlengine.parse.SqlError;

/** A window's frame (6.2): which positions of a partition the current row's frame covers. */
final class WindowFrame {
    private static final FrameSpec DEFAULT = new FrameSpec(FrameMode.RANGE,
        new FrameBound(BoundKind.UNBOUNDED_PRECEDING, null), new FrameBound(BoundKind.CURRENT_ROW, null));

    private final FrameMode mode;
    private final FrameBound start;
    private final FrameBound end;
    private final boolean desc; // direction of the first ORDER BY term, for RANGE offsets

    private WindowFrame(FrameSpec spec, boolean desc) {
        this.mode = spec.mode();
        this.start = spec.start();
        this.end = spec.end();
        this.desc = desc;
    }

    /** The frame of a window with this ORDER BY; spec is null when no frame was written. Checks 6.2's errors. */
    static WindowFrame of(FrameSpec spec, List<OrderTerm> order) {
        if (spec == null) return new WindowFrame(DEFAULT, false);
        BoundKind s = spec.start().kind();
        BoundKind e = spec.end().kind();
        if ((s == BoundKind.CURRENT_ROW && e == BoundKind.PRECEDING)
            || (s == BoundKind.FOLLOWING && (e == BoundKind.PRECEDING || e == BoundKind.CURRENT_ROW))) {
            throw new SqlError("unsupported frame specification");
        }
        String kind = spec.mode() == FrameMode.ROWS ? "integer" : "number";
        checkOffset(spec.mode(), spec.start(), "starting", kind);
        checkOffset(spec.mode(), spec.end(), "ending", kind);
        boolean offsets = hasOffset(spec.start()) || hasOffset(spec.end());
        if (spec.mode() == FrameMode.RANGE && offsets && order.size() != 1) {
            throw new SqlError("RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression");
        }
        return new WindowFrame(spec, !order.isEmpty() && order.get(0).desc());
    }

    private static boolean hasOffset(FrameBound b) {
        return b.kind() == BoundKind.PRECEDING || b.kind() == BoundKind.FOLLOWING;
    }

    private static void checkOffset(FrameMode mode, FrameBound b, String which, String kind) {
        if (!hasOffset(b)) return;
        boolean bad = b.offset().doubleValue() < 0 || (mode == FrameMode.ROWS && !(b.offset() instanceof Long));
        if (bad) throw new SqlError("frame " + which + " offset must be a non-negative " + kind);
    }

    /** First position of the frame of the row at pos. */
    int first(Partition p, int pos) {
        return switch (start.kind()) {
            case UNBOUNDED_PRECEDING -> 0;
            case UNBOUNDED_FOLLOWING -> p.size();
            case CURRENT_ROW -> mode == FrameMode.ROWS ? pos : p.peerStart[pos];
            case PRECEDING -> mode == FrameMode.ROWS ? rowsBound(p, pos, -offsetRows(start)) : rangeBound(p, pos, -1, false);
            case FOLLOWING -> mode == FrameMode.ROWS ? rowsBound(p, pos, offsetRows(start)) : rangeBound(p, pos, 1, false);
        };
    }

    /** The position after the last of the frame of the row at pos (the frame is empty when this is not after first). */
    int after(Partition p, int pos) {
        return switch (end.kind()) {
            case UNBOUNDED_PRECEDING -> 0;
            case UNBOUNDED_FOLLOWING -> p.size();
            case CURRENT_ROW -> mode == FrameMode.ROWS ? pos + 1 : p.peerEnd[pos];
            case PRECEDING -> mode == FrameMode.ROWS ? rowsBound(p, pos, -offsetRows(end) + 1) : rangeBound(p, pos, -1, true);
            case FOLLOWING -> mode == FrameMode.ROWS ? rowsBound(p, pos, offsetRows(end) + 1) : rangeBound(p, pos, 1, true);
        };
    }

    /** Offsets beyond any partition size all mean the same; clamping keeps the arithmetic from overflowing. */
    private static long offsetRows(FrameBound b) {
        return Math.min(b.offset().longValue(), 1L << 40);
    }

    private static int rowsBound(Partition p, int pos, long delta) {
        return (int) Math.max(0, Math.min(p.size(), pos + delta));
    }

    /**
     * RANGE n PRECEDING / FOLLOWING (sign -1 / +1): the first position in the numeric rows whose distance from
     * the current value (measured in ORDER BY direction) is at least sign*n, or more than it when past is set.
     * A current row with no number has only its peers in range.
     */
    private int rangeBound(Partition p, int pos, int sign, boolean past) {
        Object cur = p.orderValues[pos][0];
        if (!(cur instanceof Number c)) return past ? p.peerEnd[pos] : p.peerStart[pos];
        FrameBound b = past ? end : start;
        double target = sign * b.offset().doubleValue();
        int lo = p.numericLo;
        int hi = p.numericHi;
        while (lo < hi) {
            int mid = (lo + hi) >>> 1;
            double v = ((Number) p.orderValues[mid][0]).doubleValue();
            double d = desc ? c.doubleValue() - v : v - c.doubleValue();
            if (past ? d > target : d >= target) hi = mid;
            else lo = mid + 1;
        }
        return lo;
    }
}
