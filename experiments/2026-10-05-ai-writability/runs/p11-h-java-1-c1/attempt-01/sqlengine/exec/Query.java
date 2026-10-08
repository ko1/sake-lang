package sqlengine.exec;

import java.util.List;
import sqlengine.value.Collation;

/** A compiled select (5.1): bound once by QueryCompiler, then run any number of times. */
interface Query {
    /** The result columns: name, and the affinity (type) when the result column is a plain column reference. */
    List<Column> outputs();

    /** The result columns' expressions as written, for their collation and affinity (IN (select), 7.4). */
    List<Node> resultNodes();

    /** Per result column, the collation rows are compared under (7.4); null entries mean none (BINARY). */
    Collation[] collations();

    /** The result rows, after DISTINCT, compounding, ORDER BY, OFFSET and LIMIT. */
    List<Object[]> run();
}
