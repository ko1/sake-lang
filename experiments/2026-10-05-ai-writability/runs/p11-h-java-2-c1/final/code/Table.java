import java.util.ArrayList;
import java.util.List;
import java.util.Locale;

/**
 * A table: its columns (spelled as in CREATE TABLE), constraints derived from the definition, and rows in
 * insertion order. Rows are written only through RowChecker, which enforces the constraints.
 */
final class Table {
    /** Changed only by ALTER TABLE (Catalog.renameTable). */
    String name;
    /** Changed only by ALTER TABLE (addColumn, renameColumn). */
    final List<Stmt.ColumnDef> columns;
    final List<Object[]> rows = new ArrayList<>();
    /** Per column: storing NULL is an error (NOT NULL, or part of a PRIMARY KEY). */
    boolean[] notNull;
    /** Per column: the raw DEFAULT value (null = NULL). The INTEGER PRIMARY KEY has none. */
    Object[] defaults;
    /** Column index of the INTEGER PRIMARY KEY (the row's key), or -1. */
    final int rowidColumn;
    /** Column sets that must be unique, in declaration order (column constraints, then table constraints). */
    final List<UniqueKey> uniques = new ArrayList<>();

    /** A unique column set; colls.get(k) is the collation under which values of cols[k] are compared. */
    record UniqueKey(int[] cols, Collation[] colls) {}

    /** Derives the constraints; a constraint naming a missing column is "no such column". */
    Table(String name, List<Stmt.ColumnDef> columns, List<Stmt.TableConstraint> constraints) {
        this.name = name;
        this.columns = new ArrayList<>(columns);
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
            if (i == primary && rowid >= 0) continue;
            int[] cols = keys.get(i);
            Collation[] colls = new Collation[cols.length];
            for (int k = 0; k < cols.length; k++) colls[k] = columns.get(cols[k]).collation();
            uniques.add(new UniqueKey(cols, colls));
        }
    }

    /** An independent copy for transaction snapshots: rows are shared (never mutated), the lists are not. */
    Table copy() {
        return new Table(this);
    }

    private Table(Table o) {
        name = o.name;
        columns = new ArrayList<>(o.columns);
        rows.addAll(o.rows);
        notNull = o.notNull.clone();
        defaults = o.defaults.clone();
        rowidColumn = o.rowidColumn;
        uniques.addAll(o.uniques);
    }

    /** ALTER TABLE ADD COLUMN: appends the column; existing rows get fill (already converted). */
    void addColumn(Stmt.ColumnDef def, Object fill) {
        columns.add(def);
        notNull = java.util.Arrays.copyOf(notNull, columns.size());
        notNull[columns.size() - 1] = def.notNull();
        defaults = java.util.Arrays.copyOf(defaults, columns.size());
        defaults[columns.size() - 1] = def.defaultValue();
        for (int i = 0; i < rows.size(); i++) {
            Object[] row = java.util.Arrays.copyOf(rows.get(i), columns.size());
            row[columns.size() - 1] = fill;
            rows.set(i, row);
        }
    }

    /** ALTER TABLE RENAME COLUMN; constraints refer to columns by position, so they follow. */
    void renameColumn(int index, String newName) {
        Stmt.ColumnDef c = columns.get(index);
        columns.set(index, new Stmt.ColumnDef(newName, c.type(), c.notNull(), c.primaryKey(), c.unique(), c.defaultValue(),
            c.collation()));
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
