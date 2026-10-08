
/** Schema statements: CREATE / DROP of tables, views and indexes, and ALTER TABLE. Each is all or nothing. */
final class Ddl {
    private final Catalog catalog;

    Ddl(Catalog catalog) {
        this.catalog = catalog;
    }

    void run(Stmt s) {
        switch (s) {
            case Stmt.CreateTable c -> createTable(c);
            case Stmt.DropTable d -> dropTable(d);
            case Stmt.CreateView c -> createView(c);
            case Stmt.DropView d -> dropView(d);
            case Stmt.CreateIndex c -> createIndex(c);
            case Stmt.DropIndex d -> dropIndex(d);
            case Stmt.AlterAddColumn a -> addColumn(a);
            case Stmt.AlterRenameTable a -> renameTable(a);
            case Stmt.AlterRenameColumn a -> renameColumn(a);
            default -> throw new IllegalArgumentException(s.toString());
        }
    }

    // ---- tables and views share one name space ----

    /** Whether to skip a CREATE of a table or view called name: false to go on; else an error, or true if IF NOT EXISTS. */
    private boolean nameTaken(String name, boolean ifNotExists) {
        Table t = catalog.find(name);
        Catalog.View v = catalog.view(name);
        if (t != null || v != null) {
            if (ifNotExists) return true;
            throw new SqlError((t != null ? "table " : "view ") + name + " already exists");
        }
        if (catalog.index(name) != null) throw new SqlError("there is already an index named " + name);
        return false;
    }

    private void createTable(Stmt.CreateTable c) {
        if (nameTaken(c.table(), c.ifNotExists())) return;
        for (int i = 0; i < c.columns().size(); i++) {
            for (int j = 0; j < i; j++) {
                if (c.columns().get(j).name().equalsIgnoreCase(c.columns().get(i).name())) {
                    throw new SqlError("duplicate column name: " + c.columns().get(i).name());
                }
            }
        }
        catalog.add(new Table(c.table(), c.columns(), c.constraints()));
    }

    private void dropTable(Stmt.DropTable d) {
        if (catalog.find(d.table()) == null) {
            Catalog.View v = catalog.view(d.table());
            if (v != null) throw new SqlError("use DROP VIEW to delete view " + v.name());
            if (d.ifExists()) return;
            throw new SqlError("no such table: " + d.table());
        }
        catalog.remove(d.table());
    }

    /** The select is not checked here: an error in it shows when the view is used. */
    private void createView(Stmt.CreateView c) {
        if (nameTaken(c.name(), c.ifNotExists())) return;
        catalog.addView(new Catalog.View(c.name(), c.columns(), c.select()));
    }

    private void dropView(Stmt.DropView d) {
        if (catalog.view(d.name()) == null) {
            Table t = catalog.find(d.name());
            if (t != null) throw new SqlError("use DROP TABLE to delete table " + t.name);
            if (d.ifExists()) return;
            throw new SqlError("no such view: " + d.name());
        }
        catalog.removeView(d.name());
    }

    // ---- indexes (SPEC 5.7) ----

    private void createIndex(Stmt.CreateIndex c) {
        Table t = catalog.get(c.table());
        if (catalog.relationExists(c.name())) throw new SqlError("there is already a table named " + c.name());
        if (catalog.index(c.name()) != null) {
            if (c.ifNotExists()) return;
            throw new SqlError("index " + c.name() + " already exists");
        }
        int[] cols = new int[c.columns().size()];
        for (int i = 0; i < cols.length; i++) {
            cols[i] = t.columnIndex(c.columns().get(i));
            if (cols[i] < 0) throw new SqlError("no such column: " + c.columns().get(i));
        }
        if (c.unique()) {
            RowChecker.checkExisting(t, cols);
            t.uniques.add(cols);
        }
        catalog.addIndex(new Catalog.Index(c.name(), t.name, c.unique() ? cols : null));
    }

    private void dropIndex(Stmt.DropIndex d) {
        if (catalog.index(d.name()) == null) {
            if (d.ifExists()) return;
            throw new SqlError("no such index: " + d.name());
        }
        catalog.removeIndex(d.name());
    }

    // ---- ALTER TABLE (SPEC 5.6) ----

    private void addColumn(Stmt.AlterAddColumn a) {
        Table t = catalog.get(a.table());
        Stmt.ColumnDef def = a.column();
        if (t.columnIndex(def.name()) >= 0) throw new SqlError("duplicate column name: " + def.name());
        if (def.primaryKey()) throw new SqlError("Cannot add a PRIMARY KEY column");
        if (def.unique()) throw new SqlError("Cannot add a UNIQUE column");
        if (def.notNull() && def.defaultValue() == null && !t.rows.isEmpty()) {
            throw new SqlError("Cannot add a NOT NULL column with default value NULL");
        }
        Object fill = def.defaultValue() == null || t.rows.isEmpty()
            ? null
            : Values.store(def.defaultValue(), def.type(), t.name, def.name());
        t.addColumn(def, fill);
    }

    private void renameTable(Stmt.AlterRenameTable a) {
        Table t = catalog.get(a.table());
        if (catalog.relationExists(a.newName()) || catalog.index(a.newName()) != null) {
            throw new SqlError("there is already another table or index with this name: " + a.newName());
        }
        catalog.renameTable(t, a.newName());
    }

    private void renameColumn(Stmt.AlterRenameColumn a) {
        Table t = catalog.get(a.table());
        int i = t.columnIndex(a.column());
        if (i < 0) throw new SqlError("no such column: \"" + a.column() + "\"");
        int other = t.columnIndex(a.newName());
        if (other >= 0 && other != i) throw new SqlError("duplicate column name: " + a.newName());
        t.renameColumn(i, a.newName());
    }
}
