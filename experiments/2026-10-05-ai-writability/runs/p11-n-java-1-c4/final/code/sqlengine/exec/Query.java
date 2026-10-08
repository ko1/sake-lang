package sqlengine.exec;

import java.util.List;

/** A compiled select (5.1): bound once by QueryCompiler, then run any number of times. */
interface Query {
    /** The result columns: name, and the affinity (type) when the result column is a plain column reference. */
    List<Column> outputs();

    /** The result rows, after DISTINCT, compounding, ORDER BY, OFFSET and LIMIT. */
    List<Object[]> run();
}
