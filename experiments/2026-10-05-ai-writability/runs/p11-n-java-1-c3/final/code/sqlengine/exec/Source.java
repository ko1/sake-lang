package sqlengine.exec;

import java.util.List;

/**
 * One source of a FROM: name is null for an unnamed ( select ); offset is where its columns start in a row.
 * A table source (hasRowid) has one more slot after its real columns, holding the rowid (7.1).
 */
record Source(String name, List<Column> columns, int offset, boolean hasRowid) {

    /** Slots this source takes in a joined row. */
    int width() {
        return columns.size() + (hasRowid ? 1 : 0);
    }
}
