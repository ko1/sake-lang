import java.util.List;

/** Turns a row of raw values into a stored row, applying column types and constraints (SPEC 1.5, 2.1). */
final class RowChecker {
    private RowChecker() {}

    /**
     * Returns the row to store, or throws the first failing check in the order of SPEC 2.1 and 7.3.
     * raw has the column values and, in slot t.rowidSlot(), the rowid for a table without an INTEGER PRIMARY
     * KEY (with one, the key column is the rowid). selfIndex is the index in table.rows of the row being
     * replaced by an UPDATE (excluded from the uniqueness checks), or -1 for an INSERT, where a NULL rowid is
     * also given its automatic value.
     */
    static Object[] prepare(Table t, Object[] raw, int selfIndex) {
        Object[] row = raw.clone();
        int key = t.rowidColumn;
        int slot = t.rowidSlot();
        int source = key >= 0 ? key : slot;
        row[source] = rowidValue(t, row[source], selfIndex < 0);
        row[slot] = row[source];
        for (int i = 0; i < slot; i++) {
            if (t.notNull[i] && row[i] == null) {
                throw new SqlError("NOT NULL constraint failed: " + t.name + "." + t.columns.get(i).name());
            }
        }
        if (conflicts(t, new int[] {slot}, row, selfIndex)) throw uniqueError(t, new int[] {slot});
        for (int i = 0; i < slot; i++) {
            if (i == key) continue;
            Stmt.ColumnDef c = t.columns.get(i);
            row[i] = Values.store(row[i], c.type(), t.name, c.name());
        }
        for (int u = t.uniques.size() - 1; u >= 0; u--) {
            int[] cols = t.uniques.get(u);
            if (conflicts(t, cols, row, selfIndex)) throw uniqueError(t, cols);
        }
        return row;
    }

    /** Throws the uniqueness error if two existing rows of t agree on all of cols (a new UNIQUE index). */
    static void checkExisting(Table t, int[] cols) {
        for (int i = 0; i < t.rows.size(); i++) {
            if (conflicts(t, cols, t.rows.get(i), i)) throw uniqueError(t, cols);
        }
    }

    /** The rowid: automatic for NULL on insert, otherwise an INTEGER (after the conversion of 1.5) or "datatype mismatch". */
    private static Object rowidValue(Table t, Object v, boolean insert) {
        if (v == null) {
            if (!insert) throw new SqlError("datatype mismatch");
            long max = 0;
            boolean any = false;
            for (Object[] r : t.rows) {
                long k = (Long) r[t.rowidSlot()];
                if (!any || k > max) max = k;
                any = true;
            }
            return any ? max + 1 : 1L;
        }
        try {
            return Values.store(v, ColType.INTEGER, t.name, "rowid");
        } catch (SqlError e) {
            throw new SqlError("datatype mismatch");
        }
    }

    /** True if another row has equal values in all of cols; a NULL in cols never conflicts. */
    private static boolean conflicts(Table t, int[] cols, Object[] row, int selfIndex) {
        Object[] mine = new Object[cols.length];
        for (int k = 0; k < cols.length; k++) {
            mine[k] = row[cols[k]];
            if (mine[k] == null) return false;
        }
        List<Object[]> rows = t.rows;
        for (int i = 0; i < rows.size(); i++) {
            if (i == selfIndex) continue;
            boolean same = true;
            for (int k = 0; k < cols.length && same; k++) {
                same = Values.compare(rows.get(i)[cols[k]], mine[k]) == 0;
            }
            if (same) return true;
        }
        return false;
    }

    private static SqlError uniqueError(Table t, int[] cols) {
        StringBuilder sb = new StringBuilder("UNIQUE constraint failed: ");
        if (cols.length == 1 && cols[0] == t.rowidSlot()) {
            return new SqlError(sb.append(t.name).append('.')
                .append(t.rowidColumn >= 0 ? t.columns.get(t.rowidColumn).name() : "rowid").toString());
        }
        for (int k = 0; k < cols.length; k++) {
            if (k > 0) sb.append(", ");
            sb.append(t.name).append('.').append(t.columns.get(cols[k]).name());
        }
        return new SqlError(sb.toString());
    }
}
