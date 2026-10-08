import java.util.List;

/** LIMIT / OFFSET of a query, resolved (either may be null). */
record LimitClause(Expr limit, Expr offset) {
    static final LimitClause NONE = new LimitClause(null, null);

    /** The rows after skipping OFFSET and keeping at most LIMIT; the operands are evaluated with no row. */
    <T> List<T> apply(List<T> rows, Env env) {
        int from = (int) Math.min(skip(env), rows.size());
        int to = from + (int) Math.min(max(env), rows.size() - from);
        return rows.subList(from, to);
    }

    /** How many rows must be produced to satisfy OFFSET and LIMIT (Long.MAX_VALUE: all). */
    long needed(Env env) {
        long max = max(env);
        return max == Long.MAX_VALUE ? Long.MAX_VALUE : skip(env) + max;
    }

    private long skip(Env env) {
        return offset == null ? 0 : Math.max(value(offset, env), 0);
    }

    private long max(Env env) {
        long lim = limit == null ? -1 : value(limit, env);
        return lim < 0 ? Long.MAX_VALUE : lim;
    }

    /** An operand: read as an integer (NULL is 0). */
    private static long value(Expr e, Env env) {
        Object v = Evaluator.eval(e, env);
        if (v == null) return 0;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) (double) (Double) n;
    }
}
