import java.util.List;

/** A resolved query that yields rows: a SELECT (SelectPlan), a compound select, or a recursive WITH table. */
interface QueryPlan {
    int columnCount();

    /** Name of result column i (the alias, or the column's name), or null if it has none. */
    String name(int i);

    /** Affinity of result column i: its column's type if it is a plain column reference, else null. */
    ColType type(int i);

    /** True if the query reads a column of an enclosing query (so its rows differ per outer row). */
    boolean correlated();

    /** The result rows; outer is the environment of the enclosing query (null at the top level). */
    List<Object[]> execute(Env outer);
}
