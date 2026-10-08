import java.util.List;

/** Expression tree. The parser builds Name nodes; the Resolver replaces them with ColumnRef. */
sealed interface Expr {
    /** A literal value: null, Long, Double or String. */
    record Literal(Object value) implements Expr {}

    /** A column name as written (table is null when unqualified). */
    record Name(String table, String name) implements Expr {
        String text() {
            return table == null ? name : table + "." + name;
        }
    }

    /**
     * A resolved reference to column number index of a row: depth 0 is the current row, depth d the row of the
     * d-th enclosing query (correlated subqueries). type is the affinity, or null for none.
     */
    record ColumnRef(int index, ColType type, int depth) implements Expr {
        ColumnRef(int index, ColType type) {
            this(index, type, 0);
        }
    }

    /** Unary minus ('-') or plus ('+'). */
    record Unary(char op, Expr operand) implements Expr {}

    record Not(Expr operand) implements Expr {}

    record Binary(BinOp op, Expr left, Expr right) implements Expr {}

    /**
     * A function call as written. star marks count(*); distinct and orderBy are the aggregate-only forms
     * count(DISTINCT x) and group_concat(x ORDER BY y).
     */
    record Call(String name, List<Expr> args, boolean star, boolean distinct, List<Stmt.OrderTerm> orderBy)
        implements Expr {
        Call(String name, List<Expr> args) {
            this(name, args, false, false, List.of());
        }
    }

    /** Resolved aggregate call: the value is column index of the group row (see Grouping). name is as written. */
    record AggRef(int index, String name) implements Expr {}

    /** CASE; base is null for the searched form (conditions) and set for the simple form (values to match). */
    record Case(Expr base, List<When> whens, Expr otherwise) implements Expr {}

    record When(Expr condition, Expr result) {}

    record Between(Expr operand, Expr low, Expr high, boolean negated) implements Expr {}

    record In(Expr operand, List<Expr> items, boolean negated) implements Expr {}

    record Like(Expr operand, Expr pattern, boolean negated) implements Expr {}

    record Cast(Expr operand, ColType type) implements Expr {}

    /** Subqueries as parsed: ( select ), EXISTS ( select ), x IN ( select ). */
    record Subquery(Stmt.Select select) implements Expr {}

    record Exists(Stmt.Select select) implements Expr {}

    record InSelect(Expr operand, Stmt.Select select, boolean negated) implements Expr {}

    /** The same, resolved: the plan runs (again, if correlated) against the enclosing rows. */
    record ScalarSub(QueryPlan plan) implements Expr {}

    record ExistsSub(QueryPlan plan) implements Expr {}

    record InSub(Expr operand, QueryPlan plan, boolean negated) implements Expr {}

    /** The sub-expressions of e (direct children only; the inside of a subquery belongs to the subquery). */
    static List<Expr> children(Expr e) {
        return switch (e) {
            case Subquery x -> List.of();
            case Exists x -> List.of();
            case ScalarSub x -> List.of();
            case ExistsSub x -> List.of();
            case InSelect x -> List.of(x.operand());
            case InSub x -> List.of(x.operand());
            case Literal x -> List.of();
            case Name x -> List.of();
            case ColumnRef x -> List.of();
            case AggRef x -> List.of();
            case Unary x -> List.of(x.operand());
            case Not x -> List.of(x.operand());
            case Binary x -> List.of(x.left(), x.right());
            case Call x -> x.args();
            case Case x -> {
                List<Expr> l = new java.util.ArrayList<>();
                if (x.base() != null) l.add(x.base());
                for (When w : x.whens()) {
                    l.add(w.condition());
                    l.add(w.result());
                }
                if (x.otherwise() != null) l.add(x.otherwise());
                yield l;
            }
            case Between x -> List.of(x.operand(), x.low(), x.high());
            case In x -> {
                List<Expr> l = new java.util.ArrayList<>();
                l.add(x.operand());
                l.addAll(x.items());
                yield l;
            }
            case Like x -> List.of(x.operand(), x.pattern());
            case Cast x -> List.of(x.operand());
        };
    }

    /** The first resolved aggregate reference in e, or null. */
    static AggRef findAggRef(Expr e) {
        if (e instanceof AggRef a) return a;
        for (Expr c : children(e)) {
            AggRef a = findAggRef(c);
            if (a != null) return a;
        }
        return null;
    }

    enum BinOp {
        CONCAT, MUL, DIV, MOD, ADD, SUB, LT, LE, GT, GE, EQ, NE, IS, ISNOT, AND, OR
    }
}
