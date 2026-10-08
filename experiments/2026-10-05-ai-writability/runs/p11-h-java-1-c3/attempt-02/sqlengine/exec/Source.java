package sqlengine.exec;

import java.util.List;

/**
 * One source of a FROM: name is null for an unnamed ( select ); offset is where its columns start in a row.
 * A table source (rowid true) has one more slot after its columns: the hidden rowid (7.1).
 */
record Source(String name, List<Column> columns, int offset, boolean rowid) {

    /** Number of row slots this source takes. */
    int width() {
        return columns.size() + (rowid ? 1 : 0);
    }
}
