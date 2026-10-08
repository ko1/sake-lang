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
    /**
     * Stored rows: one value per column, then the row's rowid in the last slot (index columns.size()). For an
     * INTEGER PRIMARY KEY table the rowid slot repeats the key column's value.
     */
    final List<Object[]> rows = new ArrayList<>();
    /** Per column: storing NULL is an error (NOT NULL, or part of a PRIMARY KEY). */
    boolean[] notNull;
    /** Per column: the raw DEFAULT value (null = NULL). The INTEGER PRIMARY KEY has none. */
    Object[] defaults;
    /** Column index of the INTEGER PRIMARY KEY (the row's key), or -1. */
    final int rowidColumn;
    /** Column sets that must be unique, in declaration order (column constraints, then table constraints). */
    final List<int[]> uniques = new ArrayList<>();

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
            if (i != primary || rowid < 0) uniques.add(keys.get(i));
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
        int n = columns.size();
        for (int i = 0; i < rows.size(); i++) {
            Object[] old = rows.get(i);
            Object[] row = java.util.Arrays.copyOf(old, n + 1);
            row[n - 1] = fill;
            row[n] = old[n - 1];
            rows.set(i, row);
        }
    }

    /** ALTER TABLE RENAME COLUMN; constraints refer to columns by position, so they follow. */
    void renameColumn(int index, String newName) {
        Stmt.ColumnDef c = columns.get(index);
        columns.set(index, new Stmt.ColumnDef(newName, c.type(), c.notNull(), c.primaryKey(), c.unique(), c.defaultValue()));
    }

    /** Index of the column with this name (case-insensitive), or -1. */
    int columnIndex(String col) {
        for (int i = 0; i < columns.size(); i++) {
            if (columns.get(i).name().equalsIgnoreCase(col)) return i;
        }
        return -1;
    }

    /** True for rowid, _rowid_ and oid (case-insensitive): the names of a row's rowid (SPEC 7.1). */
    static boolean isRowidName(String name) {
        return name.equalsIgnoreCase("rowid") || name.equalsIgnoreCase("_rowid_") || name.equalsIgnoreCase("oid");
    }

    /**
     * Column index a statement's column name stores into: the real column, else the rowid (the INTEGER PRIMARY
     * KEY column if there is one, else the rowid slot, index columns.size()), else -1.
     */
    int storeIndex(String col) {
        int i = columnIndex(col);
        if (i >= 0 || !isRowidName(col)) return i;
        return rowidColumn >= 0 ? rowidColumn : columns.size();
    }

    /** Case-insensitive key for names (ASCII only). */
    static String key(String name) {
        return name.toLowerCase(Locale.ROOT);
    }
}
