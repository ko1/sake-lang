import java.util.List;

/** A resolved query that yields rows: a SELECT (SelectPlan), a compound select, or a recursive WITH table. */
interface QueryPlan {
    int columnCount();

    /** Name of result column i (the alias, or the column's name), or null if it has none. */
    String name(int i);

    /** Affinity of result column i: its column's type if it is a plain column reference, else null. */
    ColType type(int i);

    /** Collation result column i names with COLLATE in its expression (SPEC 7.3), or null. */
    Collation explicitCollation(int i);

    /** Collation result column i gets from a column (SPEC 7.3), or null. For a compound select, its column collation. */
    Collation implicitCollation(int i);

    /** Collation of result column i, explicit or implicit, or null if it has none. */
    default Collation collation(int i) {
        Collation c = explicitCollation(i);
        return c != null ? c : implicitCollation(i);
    }

    /** True if the query reads a column of an enclosing query (so its rows differ per outer row). */
    boolean correlated();

    /** The result rows; outer is the environment of the enclosing query (null at the top level). */
    List<Object[]> execute(Env outer);
}
