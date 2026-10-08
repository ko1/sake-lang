package sqlengine.exec;

import java.util.List;
import sqlengine.parse.Ast.Select;

/** A named select (5.3). Its select is compiled each time the view is used, so errors in it surface then. */
record View(String name, List<String> columns, Select select) {

    Relation open(Database db) {
        return Relation.of(QueryCompiler.compile(db, Ctes.NONE, select, null), columns, "view " + name);
    }
}
