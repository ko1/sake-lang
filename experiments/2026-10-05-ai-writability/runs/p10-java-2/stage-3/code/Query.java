import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/** Runs SELECT statements: filtering, grouping, projection, DISTINCT, ordering, LIMIT/OFFSET; result lines are appended to out. */
final class Query {
    private final Catalog catalog;
    private final StringBuilder out;

    Query(Catalog catalog, StringBuilder out) {
        this.catalog = catalog;
        this.out = out;
    }

    /** One ORDER BY term: either a result column (resultIndex >= 0) or an expression over the row. */
    private record SortKey(int resultIndex, Expr expr, Sorting.Term term) {}

    private record OutRow(Object[] values, Object[] keys) {}

    void run(Stmt.Select q) {
        Table t = q.from() == null ? null : catalog.get(q.from());
        boolean aggregate = isAggregateQuery(q);
        List<Aggregates.Spec> specs = new ArrayList<>();
        int ncols = t == null ? 0 : t.columns.size();
        Resolver plain = aggregate ? new Resolver(t).collecting(specs) : new Resolver(t);
        List<Expr> exprs = new ArrayList<>();
        List<String> aliases = new ArrayList<>();
        for (Stmt.ResultColumn rc : q.columns()) {
            if (rc.star()) {
                if (t == null) throw new SqlError("no tables specified");
                for (int i = 0; i < ncols; i++) {
                    exprs.add(new Expr.ColumnRef(i, t.columns.get(i).type()));
                    aliases.add(null);
                }
            } else {
                exprs.add(plain.resolve(rc.expr()));
                aliases.add(rc.alias());
            }
        }
        Resolver named = plain.withAliases(aliases, exprs);
        Expr where = q.where() == null ? null : named.withAggs(Resolver.Aggs.MISUSE_FUNCTION).resolve(q.where());
        List<Expr> groupBy = groupTerms(q.groupBy(), exprs, named.withAggs(Resolver.Aggs.GROUP_BY));
        if (q.having() != null && !aggregate) throw new SqlError("HAVING clause on a non-aggregate query");
        Expr having = q.having() == null ? null : named.resolve(q.having());
        Resolver orderResolver = aggregate ? named : named.withAggs(Resolver.Aggs.MISUSE_ORDER_BY);
        List<SortKey> sortKeys = sortKeys(q.orderBy(), exprs.size(), aliases, orderResolver);
        Resolver noRow = new Resolver(null);
        Long limit = q.limit() == null ? null : limitValue(noRow.resolve(q.limit()));
        Long offset = q.offset() == null ? null : limitValue(noRow.resolve(q.offset()));

        List<Object[]> source = t == null ? List.<Object[]>of(new Object[0]) : t.rows;
        List<Object[]> rows = new ArrayList<>();
        for (Object[] src : source) {
            if (where == null || Values.truth(Evaluator.eval(where, src)) == Boolean.TRUE) rows.add(src);
        }
        if (aggregate) rows = Grouping.groups(rows, groupBy, specs, ncols);

        List<OutRow> result = new ArrayList<>();
        Set<List<String>> seen = new HashSet<>();
        for (Object[] row : rows) {
            if (having != null && Values.truth(Evaluator.eval(having, row)) != Boolean.TRUE) continue;
            Object[] values = new Object[exprs.size()];
            for (int i = 0; i < values.length; i++) values[i] = Evaluator.eval(exprs.get(i), row);
            if (q.distinct() && !seen.add(Arrays.stream(values).map(Grouping::key).toList())) continue;
            Object[] keys = new Object[sortKeys.size()];
            for (int i = 0; i < keys.length; i++) {
                SortKey k = sortKeys.get(i);
                keys[i] = k.resultIndex() >= 0 ? values[k.resultIndex()] : Evaluator.eval(k.expr(), row);
            }
            result.add(new OutRow(values, keys));
        }
        List<Sorting.Term> terms = sortKeys.stream().map(SortKey::term).toList();
        if (!terms.isEmpty()) result.sort((a, b) -> Sorting.compare(terms, a.keys(), b.keys()));

        long skip = offset == null ? 0 : Math.max(offset, 0);
        long max = limit == null || limit < 0 ? Long.MAX_VALUE : limit;
        for (long i = skip; i < result.size() && i - skip < max; i++) {
            Object[] values = result.get((int) i).values();
            for (int c = 0; c < values.length; c++) {
                if (c > 0) out.append('|');
                out.append(Values.display(values[c]));
            }
            out.append('\n');
        }
    }

    /** An aggregate query has GROUP BY or an aggregate call in its result columns (SPEC 3.3). */
    private static boolean isAggregateQuery(Stmt.Select q) {
        if (!q.groupBy().isEmpty()) return true;
        for (Stmt.ResultColumn rc : q.columns()) if (!rc.star() && Aggregates.contains(rc.expr())) return true;
        return false;
    }

    /** GROUP BY terms: an integer literal is a result column's expression, anything else is resolved by r. */
    private List<Expr> groupTerms(List<Expr> terms, List<Expr> resultExprs, Resolver r) {
        List<Expr> out = new ArrayList<>();
        for (int i = 0; i < terms.size(); i++) {
            Long ordinal = ordinalOf(terms.get(i));
            if (ordinal == null) {
                out.add(r.resolve(terms.get(i)));
                continue;
            }
            if (ordinal < 1 || ordinal > resultExprs.size()) {
                throw new SqlError(ordinalName(i + 1) + " GROUP BY term out of range - should be between 1 and "
                    + resultExprs.size());
            }
            Expr e = resultExprs.get((int) (ordinal - 1));
            if (Expr.findAggRef(e) != null) {
                throw new SqlError("aggregate functions are not allowed in the GROUP BY clause");
            }
            out.add(e);
        }
        return out;
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
            keys.add(new SortKey(index, expr, new Sorting.Term(term.desc(), term.nullsFirst())));
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

    /** LIMIT / OFFSET operand: evaluated with no row, read as an integer. */
    private static long limitValue(Expr e) {
        Object v = Evaluator.eval(e, new Object[0]);
        if (v == null) return 0;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? l : (long) (double) (Double) n;
    }
}
