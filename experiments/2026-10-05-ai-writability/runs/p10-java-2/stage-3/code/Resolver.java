import java.util.List;
import java.util.Locale;

/**
 * Binds the names in an expression to the columns of one table (or to none), checks function calls, and
 * returns an expression the Evaluator can run. Name errors surface here, before any row is read.
 */
final class Resolver {
    /** What an aggregate call means where the resolver is used. */
    enum Aggs {
        /** Collected into specs and replaced by an AggRef (result columns, HAVING, ORDER BY of an aggregate query). */
        COLLECT,
        /** Not allowed (WHERE, UPDATE, DELETE, ...): "misuse of aggregate function". */
        MISUSE_FUNCTION,
        /** Not allowed in the ORDER BY of a non-aggregate query: "misuse of aggregate". */
        MISUSE_ORDER_BY,
        /** Not allowed in GROUP BY. */
        GROUP_BY
    }

    private final Table table;                       // null: no row in scope
    private final List<String> aliases;              // result-column aliases usable as names, or null
    private final List<Expr> aliasExprs;             // their (already resolved) expressions
    private final Aggs aggs;
    private final List<Aggregates.Spec> specs;       // shared by the resolvers of one SELECT; null if none
    private final int specBase;                      // number of table columns: AggRef index = specBase + slot

    Resolver(Table table) {
        this(table, null, null, Aggs.MISUSE_FUNCTION, null, 0);
    }

    private Resolver(Table table, List<String> aliases, List<Expr> aliasExprs, Aggs aggs,
                     List<Aggregates.Spec> specs, int specBase) {
        this.table = table;
        this.aliases = aliases;
        this.aliasExprs = aliasExprs;
        this.aggs = aggs;
        this.specs = specs;
        this.specBase = specBase;
    }

    /** Same resolver, with result-column aliases usable as names: aliasExprs.get(i) is column i's expression. */
    Resolver withAliases(List<String> aliases, List<Expr> aliasExprs) {
        return new Resolver(table, aliases, aliasExprs, aggs, specs, specBase);
    }

    Resolver withAggs(Aggs mode) {
        return new Resolver(table, aliases, aliasExprs, mode, specs, specBase);
    }

    /** Same resolver, collecting aggregate calls into specs (the table's column count fixes their indexes). */
    Resolver collecting(List<Aggregates.Spec> specs) {
        int base = table == null ? 0 : table.columns.size();
        return new Resolver(table, aliases, aliasExprs, Aggs.COLLECT, specs, base);
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
            case Expr.Name n -> name(n);
            case Expr.Unary u -> new Expr.Unary(u.op(), resolve(u.operand()));
            case Expr.Not n -> new Expr.Not(resolve(n.operand()));
            case Expr.Binary b -> new Expr.Binary(b.op(), resolve(b.left()), resolve(b.right()));
            case Expr.Call c -> call(c);
            case Expr.Case c -> new Expr.Case(c.base() == null ? null : resolve(c.base()),
                c.whens().stream().map(w -> new Expr.When(resolve(w.condition()), resolve(w.result()))).toList(),
                c.otherwise() == null ? null : resolve(c.otherwise()));
            case Expr.Between b ->
                new Expr.Between(resolve(b.operand()), resolve(b.low()), resolve(b.high()), b.negated());
            case Expr.In i -> new Expr.In(resolve(i.operand()), i.items().stream().map(this::resolve).toList(),
                i.negated());
            case Expr.Like l -> new Expr.Like(resolve(l.operand()), resolve(l.pattern()), l.negated());
            case Expr.Cast c -> new Expr.Cast(resolve(c.operand()), c.type());
        };
    }

    private Expr call(Expr.Call c) {
        if (Aggregates.isAggregate(c)) return aggregate(c);
        if (c.star() || c.distinct() || !c.orderBy().isEmpty()) throw SqlError.syntax();
        Functions.check(c.name(), c.args().size());
        return new Expr.Call(c.name(), c.args().stream().map(this::resolve).toList());
    }

    private Expr aggregate(Expr.Call c) {
        Aggregates.check(c);
        switch (aggs) {
            case MISUSE_FUNCTION -> throw new SqlError("misuse of aggregate function " + c.name() + "()");
            case MISUSE_ORDER_BY -> throw new SqlError("misuse of aggregate: " + c.name() + "()");
            case GROUP_BY -> throw groupByError();
            case COLLECT -> { }
        }
        Resolver inner = new Resolver(table, null, null, Aggs.MISUSE_FUNCTION, null, 0);
        List<Stmt.OrderTerm> order = c.orderBy().stream()
            .map(t -> new Stmt.OrderTerm(inner.resolve(t.expr()), t.desc(), t.nullsFirst())).toList();
        Aggregates.Spec spec = new Aggregates.Spec(c.name().toLowerCase(Locale.ROOT),
            c.args().stream().map(inner::resolve).toList(), c.star(), c.distinct(), order);
        int slot = specs.indexOf(spec);
        if (slot < 0) {
            slot = specs.size();
            specs.add(spec);
        }
        return new Expr.AggRef(specBase + slot, c.name());
    }

    private static SqlError groupByError() {
        return new SqlError("aggregate functions are not allowed in the GROUP BY clause");
    }

    /** An alias standing for an aggregate expression is only usable where aggregates are. */
    private Expr aliasTarget(Expr e) {
        Expr.AggRef agg = Expr.findAggRef(e);
        if (agg == null || aggs == Aggs.COLLECT) return e;
        if (aggs == Aggs.GROUP_BY) throw groupByError();
        throw new SqlError("misuse of aggregate: " + agg.name() + "()");
    }

    private Expr name(Expr.Name n) {
        if (table != null && (n.table() == null || n.table().equalsIgnoreCase(table.name))) {
            int i = table.columnIndex(n.name());
            if (i >= 0) return new Expr.ColumnRef(i, table.columns.get(i).type());
        }
        if (n.table() == null && aliases != null) {
            int i = findAlias(aliases, n.name());
            if (i >= 0) return aliasTarget(aliasExprs.get(i));
        }
        throw new SqlError("no such column: " + n.text());
    }
}
