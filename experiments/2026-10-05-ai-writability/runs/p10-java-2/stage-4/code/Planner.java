import java.util.ArrayList;
import java.util.List;

/**
 * Turns a parsed SELECT into a SelectPlan: builds the sources and joins of FROM, resolves every name
 * (so name errors come before any row is read), and works out the aggregate/grouping structure.
 */
final class Planner {
    private Planner() {}

    /** Plans q; outer is the resolver of the clause holding q when q is a subquery of an expression, else null. */
    static SelectPlan plan(Catalog catalog, Stmt.Select q, Resolver outer) {
        Resolver.Level level = new Resolver.Level();
        FromPlan from = q.from() == null ? FromPlan.none() : planFrom(catalog, q.from(), outer, level);
        Scope scope = from.scope();
        boolean aggregate = isAggregateQuery(q);
        List<Aggregates.Spec> specs = new ArrayList<>();
        Resolver base = Resolver.forQuery(catalog, scope, outer, level);
        Resolver plain = aggregate ? base.collecting(specs) : base;

        List<Expr> exprs = new ArrayList<>();
        List<String> aliases = new ArrayList<>();
        List<Expr> written = new ArrayList<>();
        List<String> names = new ArrayList<>();
        for (Stmt.ResultColumn rc : q.columns()) {
            if (rc.star()) {
                expandStar(rc, q.from() != null, scope, exprs, names);
                while (aliases.size() < exprs.size()) {
                    aliases.add(null);
                    written.add(null);
                }
            } else {
                exprs.add(plain.resolve(rc.expr()));
                aliases.add(rc.alias());
                written.add(rc.expr());
                names.add(rc.alias() != null ? rc.alias() : rc.expr() instanceof Expr.Name n ? n.name() : null);
            }
        }
        Resolver named = plain.withAliases(aliases, written, exprs);
        Expr where = q.where() == null ? null : named.withAggs(Resolver.Aggs.MISUSE_FUNCTION).resolve(q.where());
        List<Expr> groupBy = groupTerms(q.groupBy(), exprs, named.withAggs(Resolver.Aggs.GROUP_BY));
        if (q.having() != null && !aggregate) throw new SqlError("HAVING clause on a non-aggregate query");
        Expr having = q.having() == null ? null : named.resolve(q.having());
        Resolver orderResolver = aggregate ? named : named.withAggs(Resolver.Aggs.MISUSE_ORDER_BY);
        List<SelectPlan.SortKey> sortKeys = sortKeys(q.orderBy(), exprs.size(), aliases, orderResolver);
        Resolver noRow = Resolver.forQuery(catalog, new Scope(), outer, level);
        Expr limit = q.limit() == null ? null : noRow.resolve(q.limit());
        Expr offset = q.offset() == null ? null : noRow.resolve(q.offset());

        List<ColType> types = new ArrayList<>();
        for (Expr e : exprs) types.add(e instanceof Expr.ColumnRef c ? c.type() : null);
        return new SelectPlan(from, where, aggregate, specs, groupBy, having, q.distinct(), exprs, names, types,
            sortKeys, limit, offset, level);
    }

    // ---- FROM ----

    private static FromPlan planFrom(Catalog catalog, Stmt.From from, Resolver outer, Resolver.Level level) {
        Scope scope = new Scope();
        FromPlan.RowSource first = addSource(catalog, scope, from.first());
        List<FromPlan.Join> joins = new ArrayList<>();
        for (Stmt.Join j : from.joins()) {
            int before = scope.sources().size();
            FromPlan.RowSource source = addSource(catalog, scope, j.item());
            Scope.Source added = scope.sources().get(before);
            Expr condition = null;
            if (j.on() != null) {
                condition = Resolver.forQuery(catalog, scope.prefix(before + 1), outer, level).resolve(j.on());
            } else if (j.using() != null) {
                condition = usingCondition(scope, before, added, j.using());
            }
            joins.add(new FromPlan.Join(j.kind(), source, added.columns().size(), condition));
        }
        return new FromPlan(scope, first, joins);
    }

    /** Adds the source to scope; returns where its rows come from. */
    private static FromPlan.RowSource addSource(Catalog catalog, Scope scope, Stmt.FromItem item) {
        if (item instanceof Stmt.TableRef t) {
            Table table = catalog.get(t.table());
            scope.add(t.alias() != null ? t.alias() : table.name, table.columns.stream().map(Stmt.ColumnDef::name).toList(),
                table.columns.stream().map(Stmt.ColumnDef::type).toList());
            return () -> new ArrayList<>(table.rows);
        }
        Stmt.SubqueryRef s = (Stmt.SubqueryRef) item;
        SelectPlan plan = plan(catalog, s.select(), null);
        List<String> names = new ArrayList<>();
        List<ColType> types = new ArrayList<>();
        for (int i = 0; i < plan.columnCount(); i++) {
            names.add(plan.name(i) == null ? "" : plan.name(i));
            types.add(plan.type(i));
        }
        scope.add(s.alias(), names, types);
        return () -> plan.execute(null);
    }

    /** USING (c, ...) as the condition left.c = right.c AND ...; the right copy of each c is merged away. */
    private static Expr usingCondition(Scope scope, int before, Scope.Source added, List<String> using) {
        Scope left = scope.prefix(before);
        Expr condition = null;
        for (String c : using) {
            int l = left.first(c);
            int r = added.columnIndex(c);
            if (l == Scope.NOT_FOUND || r < 0) {
                throw new SqlError("cannot join using column " + c + " - column not present in both tables");
            }
            Expr eq = new Expr.Binary(Expr.BinOp.EQ, new Expr.ColumnRef(l, scope.typeAt(l)),
                new Expr.ColumnRef(added.offset() + r, added.types().get(r)));
            condition = condition == null ? eq : new Expr.Binary(Expr.BinOp.AND, condition, eq);
            scope.merge(added, r);
        }
        return condition;
    }

    // ---- result columns, GROUP BY, ORDER BY ----

    /** Appends the columns '*' or 'q.*' stands for; '*' leaves out the right-hand copy of a USING column. */
    private static void expandStar(Stmt.ResultColumn rc, boolean hasFrom, Scope scope, List<Expr> exprs,
                                   List<String> names) {
        List<Scope.Source> sources;
        if (rc.starTable() == null) {
            if (!hasFrom) throw new SqlError("no tables specified");
            sources = scope.sources();
        } else {
            Scope.Source s = scope.find(rc.starTable());
            if (s == null) throw new SqlError("no such table: " + rc.starTable());
            sources = List.of(s);
        }
        for (Scope.Source s : sources) {
            for (int i = 0; i < s.columns().size(); i++) {
                int flat = s.offset() + i;
                if (rc.starTable() == null && scope.isMerged(flat)) continue;
                exprs.add(new Expr.ColumnRef(flat, s.types().get(i)));
                names.add(s.columns().get(i));
            }
        }
    }

    /** An aggregate query has GROUP BY or an aggregate call in its result columns (SPEC 3.3). */
    private static boolean isAggregateQuery(Stmt.Select q) {
        if (!q.groupBy().isEmpty()) return true;
        for (Stmt.ResultColumn rc : q.columns()) if (!rc.star() && Aggregates.contains(rc.expr())) return true;
        return false;
    }

    /** GROUP BY terms: an integer literal is a result column's expression, anything else is resolved by r. */
    private static List<Expr> groupTerms(List<Expr> terms, List<Expr> resultExprs, Resolver r) {
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

    private static List<SelectPlan.SortKey> sortKeys(List<Stmt.OrderTerm> terms, int nResult, List<String> aliases,
                                                      Resolver r) {
        List<SelectPlan.SortKey> keys = new ArrayList<>();
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
            keys.add(new SelectPlan.SortKey(index, expr, new Sorting.Term(term.desc(), term.nullsFirst())));
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
}
