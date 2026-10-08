import java.util.List;
import java.util.Locale;

/**
 * Binds the names in an expression to the columns of the sources of one query (and, for a subquery, of the
 * queries around it), checks function calls, plans subqueries, and returns an expression the Evaluator can
 * run. Name errors surface here, before any row is read.
 */
final class Resolver {
    /** What an aggregate call means where the resolver is used. */
    enum Aggs {
        /** Collected into specs and replaced by an AggRef (result columns, HAVING, ORDER BY of an aggregate query). */
        COLLECT,
        /** Not allowed (WHERE, ON, UPDATE, DELETE, ...): "misuse of aggregate function". */
        MISUSE_FUNCTION,
        /** Not allowed in the ORDER BY of a non-aggregate query: "misuse of aggregate". */
        MISUSE_ORDER_BY,
        /** Not allowed in GROUP BY. */
        GROUP_BY
    }

    /** State shared by all the resolvers of one query. */
    static final class Level {
        /** Set when some expression of the query reads a column of an enclosing query. */
        boolean correlated;
    }

    private final Catalog catalog;
    private final Scope scope;
    private final Resolver outer;                    // the resolver of the clause that holds this subquery, or null
    private final Level level;
    private final List<String> aliases;              // result-column aliases usable as names, or null
    private final List<Expr> aliasSources;           // their expressions as written (null entries for '*' columns)
    private final List<Expr> aliasExprs;             // their (already resolved) expressions
    private final Aggs aggs;
    private final List<Aggregates.Spec> specs;       // shared by the resolvers of one SELECT; null if none
    private final int shift;                         // added to every column depth (alias of an enclosing query)
    private final Windows.Collector windows;         // where window calls are collected; null where they are misuse

    private Resolver(Catalog catalog, Scope scope, Resolver outer, Level level, List<String> aliases,
                     List<Expr> aliasSources, List<Expr> aliasExprs, Aggs aggs, List<Aggregates.Spec> specs,
                     int shift, Windows.Collector windows) {
        this.catalog = catalog;
        this.scope = scope;
        this.outer = outer;
        this.level = level;
        this.aliases = aliases;
        this.aliasSources = aliasSources;
        this.aliasExprs = aliasExprs;
        this.aggs = aggs;
        this.specs = specs;
        this.shift = shift;
        this.windows = windows;
    }

    /**
     * Resolver for the columns of scope; outer is the resolver of the enclosing query's clause, or null. All
     * the resolvers of one query take the same level.
     */
    static Resolver forQuery(Catalog catalog, Scope scope, Resolver outer, Level level) {
        return new Resolver(catalog, scope, outer, level, null, null, null, Aggs.MISUSE_FUNCTION, null, 0, null);
    }

    /** Resolver for a statement on one table (UPDATE, DELETE): its columns are the row. */
    static Resolver of(Catalog catalog, Table table) {
        Scope scope = new Scope();
        scope.add(table.name, table.columns.stream().map(Stmt.ColumnDef::name).toList(),
            table.columns.stream().map(Stmt.ColumnDef::type).toList(),
            table.columns.stream().map(Stmt.ColumnDef::collation).toList());
        return forQuery(catalog, scope, null, new Level());
    }

    /** Resolver where no column is in scope. */
    static Resolver empty(Catalog catalog) {
        return forQuery(catalog, new Scope(), null, new Level());
    }

    /** True if some expression resolved so far reads a column of an enclosing query. */
    boolean correlated() {
        return level.correlated;
    }

    /** Same resolver, with result-column aliases usable as names: exprs.get(i) is column i's resolved expression. */
    Resolver withAliases(List<String> aliases, List<Expr> sources, List<Expr> exprs) {
        return new Resolver(catalog, scope, outer, level, aliases, sources, exprs, aggs, specs, shift, windows);
    }

    Resolver withAggs(Aggs mode) {
        return new Resolver(catalog, scope, outer, level, aliases, aliasSources, aliasExprs, mode, specs, shift, windows);
    }

    /** Same resolver, collecting aggregate calls into specs (the row width fixes their indexes). */
    Resolver collecting(List<Aggregates.Spec> specs) {
        return new Resolver(catalog, scope, outer, level, aliases, aliasSources, aliasExprs, Aggs.COLLECT, specs,
            shift, windows);
    }

    private Resolver shifted(int by) {
        return new Resolver(catalog, scope, outer, level, aliases, aliasSources, aliasExprs, aggs, specs, by, windows);
    }

    /** Resolver for the inside of an aggregate call: no aliases, no nested aggregates. */
    private Resolver inner() {
        return new Resolver(catalog, scope, outer, level, null, null, null, Aggs.MISUSE_FUNCTION, null, shift, null);
    }

    /** Resolver for the inside of a window call (arguments, PARTITION BY, ORDER BY): aggregates as here, no aliases. */
    private Resolver forWindow() {
        return new Resolver(catalog, scope, outer, level, null, null, null, aggs, specs, shift, null);
    }

    /** Same resolver, collecting window calls into windows. */
    Resolver collectingWindows(Windows.Collector windows) {
        return new Resolver(catalog, scope, outer, level, aliases, aliasSources, aliasExprs, aggs, specs, shift,
            windows);
    }

    /** Same resolver, where a window call is misuse (WHERE, GROUP BY, HAVING). */
    Resolver withoutWindows() {
        return collectingWindows(null);
    }

    /** Index of the result column with this alias, or -1. */
    static int findAlias(List<String> aliases, String name) {
        for (int i = 0; i < aliases.size(); i++) {
            if (aliases.get(i) != null && aliases.get(i).equalsIgnoreCase(name)) return i;
        }
        return -1;
    }

    Expr resolve(Expr e) {
        return switch (e) {
            case Expr.Literal l -> l;
            case Expr.ColumnRef c -> c;
            case Expr.AggRef a -> a;
            case Expr.ScalarSub s -> s;
            case Expr.ExistsSub s -> s;
            case Expr.InSub s -> s;
            case Expr.Name n -> name(n);
            case Expr.Unary u -> new Expr.Unary(u.op(), resolve(u.operand()));
            case Expr.Not n -> new Expr.Not(resolve(n.operand()));
            case Expr.Binary b -> binary(b);
            case Expr.Call c -> call(c);
            case Expr.WindowCall w -> window(w);
            case Expr.WinRef w -> w;
            case Expr.Case c -> new Expr.Case(c.base() == null ? null : operand(c.base(), true),
                c.whens().stream().map(w -> new Expr.When(resolve(w.condition()), resolve(w.result()))).toList(),
                c.otherwise() == null ? null : resolve(c.otherwise()));
            case Expr.Between b ->
                new Expr.Between(operand(b.operand(), true), operand(b.low(), true), operand(b.high(), true),
                    b.negated());
            case Expr.In i -> new Expr.In(resolve(i.operand()), i.items().stream().map(this::resolve).toList(),
                i.negated());
            case Expr.Like l -> new Expr.Like(resolve(l.operand()), resolve(l.pattern()), l.negated());
            case Expr.Cast c -> new Expr.Cast(resolve(c.operand()), c.type());
            case Expr.Collate c -> new Expr.Collate(resolve(c.operand()), c.name(), Collation.lookup(c.name()));
            case Expr.Subquery s -> scalarSubquery(s, false);
            case Expr.Exists s -> new Expr.ExistsSub(Planner.plan(catalog, s.select(), this));
            case Expr.InSelect s -> inSubquery(s);
        };
    }

    private Expr binary(Expr.Binary b) {
        boolean compares = switch (b.op()) {
            case LT, LE, GT, GE, EQ, NE, IS, ISNOT -> true;
            default -> false;
        };
        if (!compares) return new Expr.Binary(b.op(), resolve(b.left()), resolve(b.right()));
        boolean isTest = b.op() == Expr.BinOp.IS || b.op() == Expr.BinOp.ISNOT;
        boolean leftIsRow = !(isTest && isNullLiteral(b.right()));
        boolean rightIsRow = !(isTest && isNullLiteral(b.left()));
        return new Expr.Binary(b.op(), operand(b.left(), leftIsRow), operand(b.right(), rightIsRow));
    }

    private static boolean isNullLiteral(Expr e) {
        return e instanceof Expr.Literal l && l.value() == null;
    }

    /** An operand of a comparison, BETWEEN or CASE x: a multi-column scalar subquery there is "row value misused". */
    private Expr operand(Expr e, boolean rowValueContext) {
        if (e instanceof Expr.Subquery s) return scalarSubquery(s, rowValueContext);
        return resolve(e);
    }

    private Expr scalarSubquery(Expr.Subquery s, boolean rowValueContext) {
        QueryPlan plan = Planner.plan(catalog, s.select(), this);
        if (plan.columnCount() != 1) {
            throw rowValueContext ? new SqlError("row value misused") : columnCountError(plan);
        }
        return new Expr.ScalarSub(plan);
    }

    private Expr inSubquery(Expr.InSelect s) {
        Expr operand = resolve(s.operand());
        QueryPlan plan = Planner.plan(catalog, s.select(), this);
        if (plan.columnCount() != 1) throw columnCountError(plan);
        return new Expr.InSub(operand, plan, s.negated());
    }

    private static SqlError columnCountError(QueryPlan plan) {
        return new SqlError("sub-select returns " + plan.columnCount() + " columns - expected 1");
    }

    private Expr call(Expr.Call c) {
        if (Windows.isWindowOnly(c.name())) throw misuseWindow(c.name());
        if (Aggregates.isAggregate(c)) return aggregate(c);
        if (c.star() || c.distinct() || !c.orderBy().isEmpty()) throw SqlError.syntax();
        Functions.check(c.name(), c.args().size());
        return new Expr.Call(c.name(), c.args().stream().map(this::resolve).toList());
    }

    private static SqlError misuseWindow(String name) {
        return new SqlError("misuse of window function " + name + "()");
    }

    private Expr window(Expr.WindowCall w) {
        Expr.Call c = w.call();
        if (windows == null) throw misuseWindow(c.name());
        String name = c.name().toLowerCase(Locale.ROOT);
        if (Windows.isWindowOnly(name)) {
            if (c.star() || c.distinct() || !c.orderBy().isEmpty()) throw SqlError.syntax();
            Windows.checkArgs(name, c.args().size());
        } else if (Aggregates.isAggregate(c)) {
            Aggregates.check(c);
            if (c.distinct() || !c.orderBy().isEmpty()) throw new SqlError("DISTINCT is not supported for window functions");
        } else {
            throw new SqlError(c.name() + "() may not be used as a window function");
        }
        Stmt.WindowSpec spec = windows.effective(w.spec());
        Windows.checkFrame(spec);
        Resolver r = forWindow();
        List<Expr> partition = spec.partition().stream().map(r::resolve).toList();
        List<Stmt.OrderTerm> order = spec.order().stream()
            .map(t -> new Stmt.OrderTerm(r.resolve(t.expr()), t.desc(), t.nullsFirst())).toList();
        Windows.Call call = new Windows.Call(name, c.args().stream().map(r::resolve).toList(), c.star(), partition,
            order, spec.frame());
        return new Expr.WinRef(windows.add(call), c.name());
    }

    private Expr aggregate(Expr.Call c) {
        Aggregates.check(c);
        switch (aggs) {
            case MISUSE_FUNCTION -> throw new SqlError("misuse of aggregate function " + c.name() + "()");
            case MISUSE_ORDER_BY -> throw new SqlError("misuse of aggregate: " + c.name() + "()");
            case GROUP_BY -> throw groupByError();
            case COLLECT -> { }
        }
        Resolver inner = inner();
        List<Stmt.OrderTerm> order = c.orderBy().stream()
            .map(t -> new Stmt.OrderTerm(inner.resolve(t.expr()), t.desc(), t.nullsFirst())).toList();
        Aggregates.Spec spec = new Aggregates.Spec(c.name().toLowerCase(Locale.ROOT),
            c.args().stream().map(inner::resolve).toList(), c.star(), c.distinct(), order);
        int slot = specs.indexOf(spec);
        if (slot < 0) {
            slot = specs.size();
            specs.add(spec);
        }
        return new Expr.AggRef(scope.width() + slot, c.name());
    }

    private static SqlError groupByError() {
        return new SqlError("aggregate functions are not allowed in the GROUP BY clause");
    }

    /** An alias standing for an aggregate expression is only usable where aggregates are. */
    private Expr aliasTarget(Expr e, String alias) {
        if (windows == null && Expr.findWinRef(e) != null) throw new SqlError("misuse of aliased window function " + alias);
        Expr.AggRef agg = Expr.findAggRef(e);
        if (agg == null || aggs == Aggs.COLLECT) return e;
        if (aggs == Aggs.GROUP_BY) throw groupByError();
        throw new SqlError("misuse of aggregate: " + agg.name() + "()");
    }

    /** A column of this query's sources, else an alias, else (for a subquery) the same in each enclosing query. */
    private Expr name(Expr.Name n) {
        int depth = shift;
        for (Resolver r = this; r != null; r = r.outer, depth++) {
            if (n.table() != null) {
                Scope.Source s = r.scope.find(n.table());
                if (s != null) {
                    int c = s.columnIndex(n.name());
                    if (c < 0) break;
                    return columnRef(r, s.offset() + c, depth);
                }
                continue;
            }
            int flat = r.scope.lookup(n.name());
            if (flat == Scope.AMBIGUOUS) throw new SqlError("ambiguous column name: " + n.name());
            if (flat >= 0) return columnRef(r, flat, depth);
            int a = r.aliases == null ? -1 : findAlias(r.aliases, n.name());
            if (a < 0) continue;
            if (r == this) return aliasTarget(aliasExprs.get(a), r.aliases.get(a));
            markCorrelated(r);
            return r.shifted(depth).resolve(r.aliasSources.get(a));
        }
        throw new SqlError("no such column: " + n.text());
    }

    private Expr columnRef(Resolver found, int flat, int depth) {
        markCorrelated(found);
        return new Expr.ColumnRef(flat, found.scope.typeAt(flat), found.scope.collationAt(flat), depth);
    }

    /** The query of this resolver reads a column of found, an enclosing query: it and those between are correlated. */
    private void markCorrelated(Resolver found) {
        for (Resolver r = this; r != found; r = r.outer) r.level.correlated = true;
    }
}
