package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.value.Names;

/** A table: columns in declaration order, rows in insertion order. */
public final class Table {
    public final String name;
    public final List<Column> columns;
    public final List<Object[]> rows = new ArrayList<>();

    public Table(String name, List<Column> columns) {
        this.name = name;
        this.columns = columns;
    }

    /** Index of the column with this name, or -1. */
    public int columnIndex(String col) {
        for (int i = 0; i < columns.size(); i++) {
            if (Names.same(columns.get(i).name(), col)) return i;
        }
        return -1;
    }
}
