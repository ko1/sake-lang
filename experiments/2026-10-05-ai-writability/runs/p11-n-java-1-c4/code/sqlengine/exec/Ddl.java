package sqlengine.exec;

import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;

/** CREATE / DROP of tables, views and indexes, and ALTER TABLE (5.3, 5.6, 5.7). Errors leave nothing changed. */
final class Ddl {
    private final Database db;

    Ddl(Database db) {
        this.db = db;
    }

    // ---- tables ----
    void createTable(CreateTable c) {
        Table existing = db.find(c.name());
        View view = db.findView(c.name());
        if (existing != null || view != null) {
            if (c.ifNotExists()) return;
            throw new SqlError(existing != null ? "table " + c.name() + " already exists"
                : "view " + view.name() + " already exists");
        }
        requireNoIndexNamed(c.name());
        db.add(SchemaBuilder.build(c));
    }

    void dropTable(DropTable d) {
        if (db.find(d.name()) == null) {
            View v = db.findView(d.name());
            if (v != null) throw new SqlError("use DROP VIEW to delete view " + v.name());
            if (d.ifExists()) return;
            throw new SqlError("no such table: " + d.name());
        }
        db.remove(d.name());
    }

    // ---- views ----
    void createView(CreateView c) {
        Table t = db.find(c.name());
        View v = db.findView(c.name());
        if (t != null || v != null) {
            if (c.ifNotExists()) return;
            throw new SqlError(t != null ? "table " + c.name() + " already exists"
                : "view " + v.name() + " already exists");
        }
        requireNoIndexNamed(c.name());
        db.addView(new View(c.name(), c.columns(), c.select()));
    }

    void dropView(DropView d) {
        if (db.findView(d.name()) == null) {
            Table t = db.find(d.name());
            if (t != null) throw new SqlError("use DROP TABLE to delete table " + t.name);
            if (d.ifExists()) return;
            throw new SqlError("no such view: " + d.name());
        }
        db.removeView(d.name());
    }

    private void requireNoIndexNamed(String name) {
        if (db.tableWithIndex(name) != null) throw new SqlError("there is already an index named " + name);
    }

    // ---- indexes ----
    void createIndex(CreateIndex c) {
        Table t = db.find(c.table());
        if (t == null) {
            if (db.findView(c.table()) != null) throw new SqlError("views may not be indexed");
            throw new SqlError("no such table: " + c.table());
        }
        if (db.find(c.name()) != null || db.findView(c.name()) != null) {
            throw new SqlError("there is already a table named " + c.name());
        }
        if (db.tableWithIndex(c.name()) != null) {
            if (c.ifNotExists()) return;
            throw new SqlError("index " + c.name() + " already exists");
        }
        int[] cols = new int[c.columns().size()];
        for (int i = 0; i < cols.length; i++) {
            cols[i] = t.columnIndex(c.columns().get(i));
            if (cols[i] < 0) throw new SqlError("no such column: " + c.columns().get(i));
        }
        t.addIndex(c.name(), cols, c.unique());
    }

    void dropIndex(DropIndex d) {
        Table t = db.tableWithIndex(d.name());
        if (t == null) {
            if (d.ifExists()) return;
            throw new SqlError("no such index: " + d.name());
        }
        t.dropIndex(t.findIndex(d.name()));
    }

    // ---- ALTER TABLE ----
    void alterTable(AlterTable a) {
        Table t = db.find(a.table());
        if (t == null) {
            if (db.findView(a.table()) != null) throw new SqlError("view " + a.table() + " may not be altered");
            throw new SqlError("no such table: " + a.table());
        }
        if (a.change() instanceof AddColumn add) addColumn(t, add.column());
        else if (a.change() instanceof RenameTable rt) renameTable(t, rt.newName());
        else renameColumn(t, (RenameColumn) a.change());
    }

    private void addColumn(Table t, ColumnDef d) {
        if (t.columnIndex(d.name()) >= 0) throw new SqlError("duplicate column name: " + d.name());
        boolean notNull = false;
        boolean primary = false;
        boolean unique = false;
        Object defaultValue = null;
        for (ColumnConstraint k : d.constraints()) {
            switch (k.kind()) {
                case NOT_NULL -> notNull = true;
                case PRIMARY_KEY -> primary = true;
                case UNIQUE -> unique = true;
                case DEFAULT -> defaultValue = k.value();
            }
        }
        if (primary) throw new SqlError("Cannot add a PRIMARY KEY column");
        if (unique) throw new SqlError("Cannot add a UNIQUE column");
        if (notNull && defaultValue == null && !t.rows().isEmpty()) {
            throw new SqlError("Cannot add a NOT NULL column with default value NULL");
        }
        t.addColumn(new Column(d.name(), d.type(), notNull, defaultValue));
    }

    private void renameTable(Table t, String newName) {
        if (db.nameTaken(newName)) {
            throw new SqlError("there is already another table or index with this name: " + newName);
        }
        db.rename(t, newName);
    }

    private static void renameColumn(Table t, RenameColumn r) {
        int idx = t.columnIndex(r.column());
        if (idx < 0) throw new SqlError("no such column: \"" + r.column() + "\"");
        t.renameColumn(idx, r.newName());
    }
}
