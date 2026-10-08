package sqlengine.exec;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.Names;
import sqlengine.value.SqlType;

/** Turns a CREATE TABLE statement into a Table, resolving its constraints (2.1). */
final class SchemaBuilder {
    private SchemaBuilder() { }

    static Table build(CreateTable c) {
        Set<String> seen = new HashSet<>();
        for (ColumnDef d : c.columns()) {
            if (!seen.add(Names.norm(d.name()))) throw new SqlError("duplicate column name: " + d.name());
        }
        int n = c.columns().size();
        boolean[] notNull = new boolean[n];
        Object[] defaults = new Object[n];
        Collation[] collations = new Collation[n];
        java.util.Arrays.fill(collations, Collation.BINARY);
        List<int[]> uniqueCols = new ArrayList<>();
        int[] primary = null;

        // Constraints in declaration order: column constraints by column, then table constraints.
        for (int i = 0; i < n; i++) {
            for (ColumnConstraint k : c.columns().get(i).constraints()) {
                switch (k.kind()) {
                    case NOT_NULL -> notNull[i] = true;
                    case DEFAULT -> defaults[i] = k.value();
                    case COLLATE -> collations[i] = Column.collationNamed((String) k.value());
                    case UNIQUE -> uniqueCols.add(new int[] {i});
                    case PRIMARY_KEY -> {
                        primary = new int[] {i};
                        uniqueCols.add(primary);
                    }
                }
            }
        }
        for (TableConstraint tc : c.constraints()) {
            int[] cols = new int[tc.columns().size()];
            for (int j = 0; j < cols.length; j++) cols[j] = indexOf(c, tc.columns().get(j));
            uniqueCols.add(cols);
            if (tc.primaryKey()) primary = cols;
        }

        int rowKey = -1;
        if (primary != null) {
            if (primary.length == 1 && c.columns().get(primary[0]).type() == SqlType.INTEGER) {
                rowKey = primary[0];
                final int[] key = primary;
                uniqueCols.removeIf(u -> u == key); // the rowid key is checked separately
            } else {
                for (int i : primary) notNull[i] = true;
            }
        }

        List<Column> cols = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            ColumnDef d = c.columns().get(i);
            cols.add(new Column(d.name(), d.type(), notNull[i], defaults[i], collations[i]));
        }
        List<UniqueKey> uniques = new ArrayList<>();
        for (int[] u : uniqueCols) {
            Collation[] keyCollations = new Collation[u.length];
            for (int j = 0; j < u.length; j++) keyCollations[j] = collations[u[j]];
            uniques.add(new UniqueKey(u, keyCollations));
        }
        return new Table(c.name(), cols, rowKey, uniques);
    }

    private static int indexOf(CreateTable c, String name) {
        for (int i = 0; i < c.columns().size(); i++) {
            if (Names.same(c.columns().get(i).name(), name)) return i;
        }
        throw new SqlError("no such column: " + name);
    }
}
