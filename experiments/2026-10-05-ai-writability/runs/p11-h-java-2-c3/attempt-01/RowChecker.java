import java.util.List;

/** Turns a row of raw values into a stored row, applying column types and constraints (SPEC 1.5, 2.1). */
final class RowChecker {
    private RowChecker() {}

    /**
     * Returns the row to store, or throws the first failing check in the order of SPEC 2.1.
     * selfIndex is the index in table.rows of the row being replaced by an UPDATE (excluded from the
     * uniqueness checks), or -1 for an INSERT, where a NULL key is also given its automatic value.
     */
    static Object[] prepare(Table t, Object[] raw, int selfIndex) {
        Object[] row = raw.clone();
        int n = t.columns.size();
        int key = t.rowidColumn;
        row[n] = rowidValue(t, row[key >= 0 ? key : n], selfIndex < 0);
        if (key >= 0) row[key] = row[n];
        for (int i = 0; i < n; i++) {
            if (t.notNull[i] && row[i] == null) {
                throw new SqlError("NOT NULL constraint failed: " + t.name + "." + t.columns.get(i).name());
            }
        }
        int[] idCols = {key >= 0 ? key : n};
        if (conflicts(t, idCols, row, selfIndex)) throw uniqueError(t, idCols);
        for (int i = 0; i < n; i++) {
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

    /** The rowid: automatic for NULL on insert, otherwise an INTEGER or "datatype mismatch" (SPEC 7.3). */
    private static Object rowidValue(Table t, Object v, boolean insert) {
        if (v == null) {
            if (!insert) throw new SqlError("datatype mismatch");
            long max = 0;
            boolean any = false;
            for (Object[] r : t.rows) {
                long k = (Long) r[t.columns.size()];
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
        for (int k = 0; k < cols.length; k++) {
            if (k > 0) sb.append(", ");
            sb.append(t.name).append('.').append(cols[k] < t.columns.size() ? t.columns.get(cols[k]).name() : "rowid");
        }
        return new SqlError(sb.toString());
    }
}
