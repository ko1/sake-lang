package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/**
 * A table: columns in declaration order, rows in insertion order, and the constraints of 2.1.
 * All writes go through insert/replace, which check a row and store it converted (1.5).
 * A stored row has one slot per column followed by one more for the rowid (7); with an INTEGER
 * PRIMARY KEY the slot repeats that column's value, which stays the authoritative copy.
 */
public final class Table {
    /** The type of the rowid slot, which Layout reports as its column. */
    static final Column ROWID_COLUMN = new Column("rowid", SqlType.INTEGER, false, null);

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

    /** Adds an index; a unique one is checked against the rows now and then before every older constraint. */
    void addIndex(String indexName, int[] cols, boolean unique) {
        UniqueKey key = null;
        if (unique) {
            key = new UniqueKey(cols);
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
            Object[] old = rows.get(i);
            Object[] grown = new Object[columns.size() + 1];
            System.arraycopy(old, 0, grown, 0, old.length - 1);
            grown[columns.size() - 1] = fill;
            grown[columns.size()] = old[old.length - 1]; // the rowid stays last
            rows.set(i, grown);
        }
    }

    void renameColumn(int idx, String newName) {
        Column c = columns.get(idx);
        columns.set(idx, new Column(newName, c.type(), c.notNull(), c.defaultValue()));
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

    /** Slots of a stored row: the columns and the rowid. */
    public int rowWidth() {
        return columns.size() + 1;
    }

    /** The slot a rowid name stands for: the INTEGER PRIMARY KEY column if there is one, else the rowid slot. */
    public int rowidIndex() {
        return rowKey >= 0 ? rowKey : columns.size();
    }

    /**
     * A row for INSERT: the supplied values (indexed by slot, rowWidth() long; null where none) with
     * defaults filled in (not for the rowid, which is assigned when stored).
     */
    public Object[] newRow(Object[] supplied, boolean[] given) {
        Object[] raw = new Object[rowWidth()];
        for (int i = 0; i < raw.length; i++) {
            if (given[i]) raw[i] = supplied[i];
            else if (i < columns.size() && i != rowKey) raw[i] = columns.get(i).defaultValue();
        }
        return raw;
    }

    /** Checks raw (unconverted values) and appends it; a NULL rowid gets the next one. */
    public void insert(Object[] raw) {
        rows.add(check(raw, -1, true));
    }

    /** Checks raw as the new content of row idx and stores it. */
    public void replace(int idx, Object[] raw) {
        rows.set(idx, check(raw, idx, false));
    }

    // ---- row checks in the order of 2.1 and 7.3 ----
    private Object[] check(Object[] raw, int self, boolean generateKey) {
        Object[] row = raw.clone();
        int slot = columns.size();
        int key = rowidIndex();
        row[key] = rowidValue(row[key], generateKey);
        for (int i = 0; i < slot; i++) {
            if (i != rowKey && columns.get(i).notNull() && row[i] == null) {
                throw new SqlError("NOT NULL constraint failed: " + name + "." + columns.get(i).name());
            }
        }
        checkUnique(new UniqueKey(new int[] {key}), row, self);
        for (int i = 0; i < slot; i++) {
            if (i != rowKey) row[i] = columns.get(i).store(row[i], name);
        }
        for (int k = uniques.size() - 1; k >= 0; k--) checkUnique(uniques.get(k), row, self);
        row[slot] = row[key];
        return row;
    }

    private Object rowidValue(Object v, boolean generate) {
        if (v == null) {
            if (!generate) throw new SqlError("datatype mismatch");
            int key = rowidIndex();
            long max = 0;
            boolean any = false;
            for (Object[] r : rows) {
                long k = (Long) r[key];
                if (!any || k > max) max = k;
                any = true;
            }
            return any ? max + 1 : 1L;
        }
        try {
            return (rowKey >= 0 ? columns.get(rowKey) : ROWID_COLUMN).store(v, name);
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
            for (int c : key.columns()) {
                if (other[c] == null || Values.compare(other[c], row[c]) != 0) {
                    same = false;
                    break;
                }
            }
            if (same) {
                StringBuilder sb = new StringBuilder("UNIQUE constraint failed: ");
                for (int j = 0; j < key.columns().length; j++) {
                    if (j > 0) sb.append(", ");
                    int c = key.columns()[j];
                    sb.append(name).append('.').append(c < columns.size() ? columns.get(c).name() : "rowid");
                }
                throw new SqlError(sb.toString());
            }
        }
    }
}
