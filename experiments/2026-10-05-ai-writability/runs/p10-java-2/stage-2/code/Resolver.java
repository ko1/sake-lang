import java.util.List;

/**
 * Binds the names in an expression to the columns of one table (or to none), checks function calls, and
 * returns an expression the Evaluator can run. Name errors surface here, before any row is read.
 */
final class Resolver {
    private final Table table;                       // null: no row in scope
    private final List<String> aliases;              // result-column aliases usable as names, or null
    private final List<Expr> aliasExprs;             // their (already resolved) expressions

    Resolver(Table table) {
        this(table, null, null);
    }

    /** aliases.get(i) is the alias of result column i (or null); aliasExprs.get(i) is its expression. */
    Resolver(Table table, List<String> aliases, List<Expr> aliasExprs) {
        this.table = table;
        this.aliases = aliases;
        this.aliasExprs = aliasExprs;
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
        Functions.check(c.name(), c.args().size());
        return new Expr.Call(c.name(), c.args().stream().map(this::resolve).toList());
    }

    private Expr name(Expr.Name n) {
        if (table != null && (n.table() == null || n.table().equalsIgnoreCase(table.name))) {
            int i = table.columnIndex(n.name());
            if (i >= 0) return new Expr.ColumnRef(i, table.columns.get(i).type());
        }
        if (n.table() == null && aliases != null) {
            int i = findAlias(aliases, n.name());
            if (i >= 0) return aliasExprs.get(i);
        }
        throw new SqlError("no such column: " + n.text());
    }
}
