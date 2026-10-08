package sqlengine.exec;

import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;

/**
 * Runs one parsed statement against the database, and keeps the transaction state (5.5). Output goes to
 * out only if the statement succeeds.
 */
public final class Executor {
    private final Database db;
    private final SelectExecutor selects;
    private final Ddl ddl;
    private final Dml dml;
    /** The database as it was at BEGIN; null when no transaction is open. */
    private Database txnStart;

    public Executor(Database db) {
        this.db = db;
        this.selects = new SelectExecutor(db);
        this.ddl = new Ddl(db);
        this.dml = new Dml(db);
    }

    public void execute(Stmt s, StringBuilder out) {
        if (s instanceof Select q) selects.run(q, out);
        else if (s instanceof Insert i) dml.insert(i);
        else if (s instanceof Update u) dml.update(u);
        else if (s instanceof Delete d) dml.delete(d);
        else if (s instanceof CreateTable c) ddl.createTable(c);
        else if (s instanceof DropTable d) ddl.dropTable(d);
        else if (s instanceof CreateView c) ddl.createView(c);
        else if (s instanceof DropView d) ddl.dropView(d);
        else if (s instanceof CreateIndex c) ddl.createIndex(c);
        else if (s instanceof DropIndex d) ddl.dropIndex(d);
        else if (s instanceof AlterTable a) ddl.alterTable(a);
        else transaction(((Transaction) s).op());
    }

    private void transaction(TransactionOp op) {
        switch (op) {
            case BEGIN -> {
                if (txnStart != null) throw new SqlError("cannot start a transaction within a transaction");
                txnStart = db.snapshot();
            }
            case COMMIT -> {
                if (txnStart == null) throw new SqlError("cannot commit - no transaction is active");
                txnStart = null;
            }
            case ROLLBACK -> {
                if (txnStart == null) throw new SqlError("cannot rollback - no transaction is active");
                db.restore(txnStart);
                txnStart = null;
            }
        }
    }
}
