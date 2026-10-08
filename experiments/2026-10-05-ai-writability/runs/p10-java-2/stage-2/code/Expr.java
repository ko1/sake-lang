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

    /** A resolved reference to column number index of the current row. */
    record ColumnRef(int index, ColType type) implements Expr {}

    /** Unary minus ('-') or plus ('+'). */
    record Unary(char op, Expr operand) implements Expr {}

    record Not(Expr operand) implements Expr {}

    record Binary(BinOp op, Expr left, Expr right) implements Expr {}

    record Call(String name, List<Expr> args) implements Expr {}

    /** CASE; base is null for the searched form (conditions) and set for the simple form (values to match). */
    record Case(Expr base, List<When> whens, Expr otherwise) implements Expr {}

    record When(Expr condition, Expr result) {}

    record Between(Expr operand, Expr low, Expr high, boolean negated) implements Expr {}

    record In(Expr operand, List<Expr> items, boolean negated) implements Expr {}

    record Like(Expr operand, Expr pattern, boolean negated) implements Expr {}

    record Cast(Expr operand, ColType type) implements Expr {}

    enum BinOp {
        CONCAT, MUL, DIV, MOD, ADD, SUB, LT, LE, GT, GE, EQ, NE, IS, ISNOT, AND, OR
    }
}
