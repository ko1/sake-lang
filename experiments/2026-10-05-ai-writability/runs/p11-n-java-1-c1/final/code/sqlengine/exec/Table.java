package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.Names;
import sqlengine.value.Values;

/**
 * A table: columns in declaration order, rows in insertion order, and the constraints of 2.1.
 * All writes go through insert/replace, which check a row and store it converted (1.5).
 */
public final class Table {
    public String name;
    public final List<Column> columns;
    /** Index of the INTEGER PRIMARY KEY column, or -1. */
    private final int rowKey;
    /** Uniqueness constraints in declaration order. */
    private final List<UniqueKey> uniques;
    private final List<Object[]> rows = new ArrayList<>();
    /** Indexes in creation order (5.7). */
    private final List<IndexDef> indexes = new ArrayList<>();

    Table(String name, List<Column> columns, int rowKey, List<UniqueKey> uniques) {
        this.name = name;
        this.columns = columns;
        this.rowKey = rowKey;
        this.uniques = uniques;
    }

    /** An independent copy for a transaction snapshot (rows are never modified in place, so they are shared). */
    Table copy() {
        Table t = new Table(name, new ArrayList<>(columns), rowKey, new ArrayList<>(uniques));
        t.rows.addAll(rows);
        t.indexes.addAll(indexes);
        return t;
    }

    List<IndexDef> indexes() {
        return indexes;
    }

    IndexDef findIndex(String indexName) {
        for (IndexDef d : indexes) {
            if (Names.same(d.name(), indexName)) return d;
        }
        return null;
    }

    /**
     * Adds an index; a unique one, comparing column cols[j] under colls[j], is checked against the rows now and
     * then before every older constraint.
     */
    void addIndex(String indexName, int[] cols, Collation[] colls, boolean unique) {
        UniqueKey key = null;
        if (unique) {
            key = new UniqueKey(cols, colls);
            for (int r = 0; r < rows.size(); r++) checkUnique(key, rows.get(r), r);
            uniques.add(key);
        }
        indexes.add(new IndexDef(indexName, cols, key));
    }

    void dropIndex(IndexDef d) {
        indexes.remove(d);
        if (d.constraint() != null) uniques.remove(d.constraint());
    }

    /** Appends a column; existing rows get its default value converted to its type (5.6). */
    void addColumn(Column col) {
        Object fill = col.store(col.defaultValue(), name);
        columns.add(col);
        for (int i = 0; i < rows.size(); i++) {
            Object[] grown = java.util.Arrays.copyOf(rows.get(i), columns.size());
            grown[columns.size() - 1] = fill;
            rows.set(i, grown);
        }
    }

    void renameColumn(int idx, String newName) {
        Column c = columns.get(idx);
        columns.set(idx, c.renamed(newName));
    }

    /** Index of the column with this name, or -1. */
    public int columnIndex(String col) {
        for (int i = 0; i < columns.size(); i++) {
            if (Names.same(columns.get(i).name(), col)) return i;
        }
        return -1;
    }

    /** The stored rows; callers must not modify the list. */
    public List<Object[]> rows() {
        return rows;
    }

    /** An opaque copy of the current rows for rollback. */
    public List<Object[]> snapshot() {
        return new ArrayList<>(rows);
    }

    public void restore(List<Object[]> snapshot) {
        rows.clear();
        rows.addAll(snapshot);
    }

    public void deleteIf(java.util.function.Predicate<Object[]> doomed) {
        rows.removeIf(doomed);
    }

    /** A row for INSERT: the supplied values (index by column, null where none) with defaults filled in (not for the rowid key). */
    public Object[] newRow(Object[] supplied, boolean[] given) {
        Object[] raw = new Object[columns.size()];
        for (int i = 0; i < raw.length; i++) {
            raw[i] = given[i] ? supplied[i] : (i == rowKey ? null : columns.get(i).defaultValue());
        }
        return raw;
    }

    /** Checks raw (unconverted values) and appends it; a NULL INTEGER PRIMARY KEY gets the next key. */
    public void insert(Object[] raw) {
        rows.add(check(raw, -1, true));
    }

    /** Checks raw as the new content of row idx and stores it. */
    public void replace(int idx, Object[] raw) {
        rows.set(idx, check(raw, idx, false));
    }

    // ---- row checks in the order of 2.1 ----
    private Object[] check(Object[] raw, int self, boolean generateKey) {
        Object[] row = raw.clone();
        if (rowKey >= 0) row[rowKey] = keyValue(row[rowKey], generateKey);
        for (int i = 0; i < row.length; i++) {
            if (i != rowKey && columns.get(i).notNull() && row[i] == null) {
                throw new SqlError("NOT NULL constraint failed: " + name + "." + columns.get(i).name());
            }
        }
        if (rowKey >= 0) checkUnique(new UniqueKey(new int[] {rowKey}), row, self);
        for (int i = 0; i < row.length; i++) {
            if (i != rowKey) row[i] = columns.get(i).store(row[i], name);
        }
        for (int k = uniques.size() - 1; k >= 0; k--) checkUnique(uniques.get(k), row, self);
        return row;
    }

    private Object keyValue(Object v, boolean generate) {
        if (v == null) {
            if (!generate) throw new SqlError("datatype mismatch");
            long max = 0;
            boolean any = false;
            for (Object[] r : rows) {
                long k = (Long) r[rowKey];
                if (!any || k > max) max = k;
                any = true;
            }
            return any ? max + 1 : 1L;
        }
        try {
            return columns.get(rowKey).store(v, name);
        } catch (SqlError e) {
            throw new SqlError("datatype mismatch");
        }
    }

    private void checkUnique(UniqueKey key, Object[] row, int self) {
        for (int c : key.columns()) {
            if (row[c] == null) return; // NULL never conflicts
        }
        for (int r = 0; r < rows.size(); r++) {
            if (r == self) continue;
            Object[] other = rows.get(r);
            boolean same = true;
            for (int j = 0; j < key.columns().length; j++) {
                int c = key.columns()[j];
                if (other[c] == null || Values.compare(other[c], row[c], key.collations()[j]) != 0) {
                    same = false;
                    break;
                }
            }
            if (same) {
                StringBuilder sb = new StringBuilder("UNIQUE constraint failed: ");
                for (int j = 0; j < key.columns().length; j++) {
                    if (j > 0) sb.append(", ");
                    sb.append(name).append('.').append(columns.get(key.columns()[j]).name());
                }
                throw new SqlError(sb.toString());
            }
        }
    }
}
