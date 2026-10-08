/** Runs one statement: reports errors, runs DDL itself and hands the rest to Dml and Query. */
final class Executor {
    private final Catalog catalog = new Catalog();
    private final StringBuilder out;
    private final Dml dml = new Dml(catalog);
    private final Query query;

    Executor(StringBuilder out) {
        this.out = out;
        this.query = new Query(catalog, out);
    }

    /** Runs one statement text; an error becomes an "Error:" line and the statement has no effect. */
    void runStatement(String text) {
        try {
            Stmt s = Parser.parse(Lexer.tokenize(text));
            if (s != null) execute(s);
        } catch (SqlError e) {
            out.append("Error: ").append(e.getMessage()).append('\n');
        }
    }

    private void execute(Stmt s) {
        switch (s) {
            case Stmt.CreateTable c -> createTable(c);
            case Stmt.DropTable d -> dropTable(d);
            case Stmt.Insert i -> dml.insert(i);
            case Stmt.Update u -> dml.update(u);
            case Stmt.Delete d -> dml.delete(d);
            case Stmt.Select q -> query.run(q);
        }
    }

    // ---- DDL ----

    private void createTable(Stmt.CreateTable c) {
        if (catalog.find(c.table()) != null) {
            if (c.ifNotExists()) return;
            throw new SqlError("table " + c.table() + " already exists");
        }
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
            if (d.ifExists()) return;
            throw new SqlError("no such table: " + d.table());
        }
        catalog.remove(d.table());
    }
}
