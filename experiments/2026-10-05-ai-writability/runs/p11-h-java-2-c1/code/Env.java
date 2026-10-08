/** The rows an expression sees: the current row, and the row of each enclosing query (for correlated subqueries). */
record Env(Object[] row, Env outer) {
    static Env of(Object[] row) {
        return new Env(row, null);
    }

    /** Value of column index in the row depth levels out (0 = current row). */
    Object get(int depth, int index) {
        Env e = this;
        for (int d = depth; d > 0; d--) e = e.outer;
        return e.row[index];
    }
}
