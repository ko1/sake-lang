import java.util.ArrayList;
import java.util.List;

/** Runs SELECT statements: filtering, projection, ordering, LIMIT/OFFSET; result lines are appended to out. */
final class Query {
    private final Catalog catalog;
    private final StringBuilder out;

    Query(Catalog catalog, StringBuilder out) {
        this.catalog = catalog;
        this.out = out;
    }

    /** One ORDER BY term: either a result column (resultIndex >= 0) or an expression over the source row. */
    private record SortKey(int resultIndex, Expr expr, boolean desc, Boolean nullsFirst) {}

    private record OutRow(Object[] values, Object[] keys) {}

    void run(Stmt.Select q) {
        Table t = q.from() == null ? null : catalog.get(q.from());
        List<Expr> exprs = new ArrayList<>();
        List<String> aliases = new ArrayList<>();
        Resolver plain = new Resolver(t);
        for (Stmt.ResultColumn rc : q.columns()) {
            if (rc.star()) {
                if (t == null) throw new SqlError("no tables specified");
                for (int i = 0; i < t.columns.size(); i++) {
                    exprs.add(new Expr.ColumnRef(i, t.columns.get(i).type()));
                    aliases.add(null);
                }
            } else {
                exprs.add(plain.resolve(rc.expr()));
                aliases.add(rc.alias());
            }
        }
        Resolver withAliases = new Resolver(t, aliases, exprs);
        Expr where = q.where() == null ? null : withAliases.resolve(q.where());
        List<SortKey> sortKeys = sortKeys(q.orderBy(), exprs.size(), aliases, withAliases);
        Resolver noRow = new Resolver(null);
        Long limit = q.limit() == null ? null : limitValue(noRow.resolve(q.limit()));
        Long offset = q.offset() == null ? null : limitValue(noRow.resolve(q.offset()));

        List<Object[]> source = t == null ? List.<Object[]>of(new Object[0]) : t.rows;
        List<OutRow> rows = new ArrayList<>();
        for (Object[] src : source) {
            if (where != null && Values.truth(Evaluator.eval(where, src)) != Boolean.TRUE) continue;
            Object[] values = new Object[exprs.size()];
            for (int i = 0; i < values.length; i++) values[i] = Evaluator.eval(exprs.get(i), src);
            Object[] keys = new Object[sortKeys.size()];
            for (int i = 0; i < keys.length; i++) {
                SortKey k = sortKeys.get(i);
                keys[i] = k.resultIndex() >= 0 ? values[k.resultIndex()] : Evaluator.eval(k.expr(), src);
            }
            rows.add(new OutRow(values, keys));
        }
        if (!sortKeys.isEmpty()) rows.sort((a, b) -> compareRows(sortKeys, a, b));

        long skip = offset == null ? 0 : Math.max(offset, 0);
        long max = limit == null || limit < 0 ? Long.MAX_VALUE : limit;
        for (long i = skip; i < rows.size() && i - skip < max; i++) {
            Object[] values = rows.get((int) i).values();
            for (int c = 0; c < values.length; c++) {
                if (c > 0) out.append('|');
                out.append(Values.display(values[c]));
            }
            out.append('\n');
        }
    }

    private List<SortKey> sortKeys(List<Stmt.OrderTerm> terms, int nResult, List<String> aliases, Resolver r) {
        List<SortKey> keys = new ArrayList<>();
        for (int i = 0; i < terms.size(); i++) {
            Stmt.OrderTerm term = terms.get(i);
            Long ordinal = ordinalOf(term.expr());
            int index = -1;
            if (ordinal != null) {
                if (ordinal < 1 || ordinal > nResult) {
                    throw new SqlError(ordinalName(i + 1) + " ORDER BY term out of range - should be between 1 and "
                        + nResult);
                }
                index = (int) (ordinal - 1);
            } else if (term.expr() instanceof Expr.Name n && n.table() == null) {
                index = Resolver.findAlias(aliases, n.name());
            }
            Expr expr = index >= 0 ? null : r.resolve(term.expr());
            keys.add(new SortKey(index, expr, term.desc(), term.nullsFirst()));
        }
        return keys;
    }

    /** k for an integer literal or '-' integer literal term, else null. */
    private static Long ordinalOf(Expr e) {
        if (e instanceof Expr.Literal l && l.value() instanceof Long k) return k;
        if (e instanceof Expr.Unary u && u.op() == '-' && u.operand() instanceof Expr.Literal l
            && l.value() instanceof Long k) {
            return -k;
        }
        return null;
    }

    private static String ordinalName(int n) {
        int mod100 = n % 100;
        String suffix = "th";
        if (mod100 < 11 || mod100 > 13) {
            switch (n % 10) {
                case 1 -> suffix = "st";
                case 2 -> suffix = "nd";
                case 3 -> suffix = "rd";
                default -> { }
            }
        }
        return n + suffix;
    }

    private static int compareRows(List<SortKey> keys, OutRow a, OutRow b) {
        for (int i = 0; i < keys.size(); i++) {
            SortKey k = keys.get(i);
            Object x = a.keys()[i];
            Object y = b.keys()[i];
            if (x == null || y == null) {
                if (x == y) continue;
                boolean nullsFirst = k.nullsFirst() != null ? k.nullsFirst() : !k.desc();
                return (x == null) == nullsFirst ? -1 : 1;
            }
            int c = Values.compare(x, y);
            if (c != 0) return k.desc() ? -c : c;
        }
        return 0;
    }

    /** LIMIT / OFFSET operand: evaluated with no row, read as an integer. */
    private static long limitValue(Expr e) {
        Object v = Evaluator.eval(e, new Object[0]);
        if (v == null) return 0;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) (double) (Double) n;
    }
}
