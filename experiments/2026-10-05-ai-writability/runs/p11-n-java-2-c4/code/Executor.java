/** Runs one statement: reports errors, runs DDL and transaction control itself, hands the rest to Dml and Query. */
final class Executor {
    private final Catalog catalog = new Catalog();
    private final StringBuilder out;
    private final Dml dml = new Dml(catalog);
    private final Query query;
    private final Ddl ddl = new Ddl(catalog);
    /** The catalog as it was at BEGIN, while a transaction is open; else null. */
    private Catalog.Snapshot transaction;

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
            case Stmt.Insert i -> dml.insert(i);
            case Stmt.Update u -> dml.update(u);
            case Stmt.Delete d -> dml.delete(d);
            case Stmt.Select q -> query.run(q);
            case Stmt.Begin b -> begin();
            case Stmt.Commit c -> commit();
            case Stmt.Rollback r -> rollback();
            default -> ddl.run(s);
        }
    }

    // ---- transactions (SPEC 5.5) ----

    private void begin() {
        if (transaction != null) throw new SqlError("cannot start a transaction within a transaction");
        transaction = catalog.snapshot();
    }

    private void commit() {
        if (transaction == null) throw new SqlError("cannot commit - no transaction is active");
        transaction = null;
    }

    private void rollback() {
        if (transaction == null) throw new SqlError("cannot rollback - no transaction is active");
        catalog.restore(transaction);
        transaction = null;
    }
}
