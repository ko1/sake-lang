import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/** A table: its columns (spelled as in CREATE TABLE) and rows in insertion order. */
final class Table {
    final String name;
    final List<Stmt.ColumnDef> columns;
    final List<Object[]> rows = new ArrayList<>();

    Table(String name, List<Stmt.ColumnDef> columns) {
        this.name = name;
        this.columns = columns;
    }

    /** Index of the column with this name (case-insensitive), or -1. */
    int columnIndex(String col) {
        for (int i = 0; i < columns.size(); i++) {
            if (columns.get(i).name().equalsIgnoreCase(col)) return i;
        }
        return -1;
    }

    /** Case-insensitive key for names (ASCII only). */
    static String key(String name) {
        return name.toLowerCase(Locale.ROOT);
    }
}
