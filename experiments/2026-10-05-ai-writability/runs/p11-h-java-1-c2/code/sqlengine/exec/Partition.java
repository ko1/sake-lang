package sqlengine.exec;

import java.util.List;

/** One partition of a window (6.2): its rows in window order, with the peer groups and ORDER BY values. */
final class Partition {
    final List<Object[]> rows;
    /** ORDER BY term values of each row, by position. */
    final Object[][] orderValues;
    /** For each position, the first position of its peers and the position after the last. */
    final int[] peerStart;
    final int[] peerEnd;
    /** Positions numericLo..numericHi-1 hold a number as the first ORDER BY value (RANGE offsets only see them). */
    final int numericLo;
    final int numericHi;

    Partition(List<Object[]> rows, Object[][] orderValues, List<Ordering.Key> keys) {
        this.rows = rows;
        this.orderValues = orderValues;
        int n = rows.size();
        peerStart = new int[n];
        peerEnd = new int[n];
        for (int i = 0; i < n; i++) {
            boolean same = i > 0 && Ordering.compare(keys, orderValues[i - 1], orderValues[i]) == 0;
            peerStart[i] = same ? peerStart[i - 1] : i;
        }
        for (int i = n - 1; i >= 0; i--) {
            boolean same = i < n - 1 && peerStart[i + 1] == peerStart[i];
            peerEnd[i] = same ? peerEnd[i + 1] : i + 1;
        }
        int lo = n;
        int hi = 0;
        for (int i = 0; i < n; i++) {
            if (!keys.isEmpty() && orderValues[i][0] instanceof Number) {
                lo = Math.min(lo, i);
                hi = i + 1;
            }
        }
        numericLo = Math.min(lo, hi);
        numericHi = hi;
    }

    int size() {
        return rows.size();
    }
}
