package sqlengine.exec;

import sqlengine.parse.Ast.Select;
import sqlengine.value.Values;

/** Runs a top-level SELECT and appends its printed rows (1.7). */
final class SelectExecutor {
    private final Database db;

    SelectExecutor(Database db) {
        this.db = db;
    }

    void run(Select q, StringBuilder out) {
        StringBuilder buf = new StringBuilder();
        for (Object[] vals : QueryCompiler.compile(db, q, null).run()) {
            for (int c = 0; c < vals.length; c++) {
                if (c > 0) buf.append('|');
                buf.append(Values.display(vals[c]));
            }
            buf.append('\n');
        }
        out.append(buf);
    }
}
