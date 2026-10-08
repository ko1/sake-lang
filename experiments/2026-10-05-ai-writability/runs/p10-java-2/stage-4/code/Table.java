import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * A table: its columns (spelled as in CREATE TABLE), constraints derived from the definition, and rows in
 * insertion order. Rows are written only through RowChecker, which enforces the constraints.
 */
final class Table {
    final String name;
    final List<Stmt.ColumnDef> columns;
    final List<Object[]> rows = new ArrayList<>();
    /** Per column: storing NULL is an error (NOT NULL, or part of a PRIMARY KEY). */
    final boolean[] notNull;
    /** Per column: the raw DEFAULT value (null = NULL). The INTEGER PRIMARY KEY has none. */
    final Object[] defaults;
    /** Column index of the INTEGER PRIMARY KEY (the row's key), or -1. */
    final int rowidColumn;
    /** Column sets that must be unique, in declaration order (column constraints, then table constraints). */
    final List<int[]> uniques = new ArrayList<>();

    /** Derives the constraints; a constraint naming a missing column is "no such column". */
    Table(String name, List<Stmt.ColumnDef> columns, List<Stmt.TableConstraint> constraints) {
        this.name = name;
        this.columns = columns;
        int n = columns.size();
        notNull = new boolean[n];
        defaults = new Object[n];
        List<int[]> keys = new ArrayList<>();
        int primary = -2;
        for (int i = 0; i < n; i++) {
            Stmt.ColumnDef c = columns.get(i);
            notNull[i] = c.notNull();
            defaults[i] = c.defaultValue();
            if (c.primaryKey()) {
                keys.add(new int[] {i});
                primary = keys.size() - 1;
                notNull[i] = true;
            }
            if (c.unique()) keys.add(new int[] {i});
        }
        for (Stmt.TableConstraint tc : constraints) {
            int[] cols = new int[tc.columns().size()];
            for (int k = 0; k < cols.length; k++) {
                cols[k] = columnIndex(tc.columns().get(k));
                if (cols[k] < 0) throw new SqlError("no such column: " + tc.columns().get(k));
            }
            keys.add(cols);
            if (tc.primary()) {
                primary = keys.size() - 1;
                for (int c : cols) notNull[c] = true;
            }
        }
        int rowid = -1;
        if (primary >= 0 && keys.get(primary).length == 1 && columns.get(keys.get(primary)[0]).type() == ColType.INTEGER) {
            rowid = keys.get(primary)[0];
            defaults[rowid] = null;
        }
        rowidColumn = rowid;
        for (int i = 0; i < keys.size(); i++) {
            if (i != primary || rowid < 0) uniques.add(keys.get(i));
        }
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
