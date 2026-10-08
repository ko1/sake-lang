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
        int key = t.rowidColumn;
        if (key >= 0) row[key] = rowidValue(t, row[key], selfIndex < 0);
        for (int i = 0; i < row.length; i++) {
            if (t.notNull[i] && row[i] == null) {
                throw new SqlError("NOT NULL constraint failed: " + t.name + "." + t.columns.get(i).name());
            }
        }
        if (key >= 0 && conflicts(t, new int[] {key}, row, selfIndex)) throw uniqueError(t, new int[] {key});
        for (int i = 0; i < row.length; i++) {
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

    /** The INTEGER PRIMARY KEY value: automatic for NULL on insert, otherwise an INTEGER or "datatype mismatch". */
    private static Object rowidValue(Table t, Object v, boolean insert) {
        if (v == null) {
            if (!insert) throw new SqlError("datatype mismatch");
            long max = 0;
            boolean any = false;
            for (Object[] r : t.rows) {
                long k = (Long) r[t.rowidColumn];
                if (!any || k > max) max = k;
                any = true;
            }
            return any ? max + 1 : 1L;
        }
        try {
            return Values.store(v, ColType.INTEGER, t.name, t.columns.get(t.rowidColumn).name());
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
            sb.append(t.name).append('.').append(t.columns.get(cols[k]).name());
        }
        return new SqlError(sb.toString());
    }
}
