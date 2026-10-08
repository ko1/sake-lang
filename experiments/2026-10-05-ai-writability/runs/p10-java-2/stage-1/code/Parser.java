import java.util.ArrayList;
import java.util.List;

/** Recursive-descent parser for one statement (token list from Lexer). Any deviation is a syntax error. */
final class Parser {
    private final List<Token> toks;
    private int p;

    private Parser(List<Token> toks) {
        this.toks = toks;
    }

    /** Parses one statement; returns null for an empty one. */
    static Stmt parse(List<Token> toks) {
        Parser ps = new Parser(toks);
        if (ps.peek().kind() == Token.Kind.EOF) return null;
        Stmt s = ps.statement();
        if (ps.peek().kind() != Token.Kind.EOF) throw SqlError.syntax();
        return s;
    }

    // ---- token helpers ----

    private Token peek() {
        return toks.get(p);
    }

    private Token next() {
        Token t = toks.get(p);
        if (t.kind() != Token.Kind.EOF) p++;
        return t;
    }

    private boolean acceptKeyword(String kw) {
        if (peek().isKeyword(kw)) {
            p++;
            return true;
        }
        return false;
    }

    private void expectKeyword(String kw) {
        if (!acceptKeyword(kw)) throw SqlError.syntax();
    }

    private boolean acceptOp(String op) {
        if (peek().isOp(op)) {
            p++;
            return true;
        }
        return false;
    }

    private void expectOp(String op) {
        if (!acceptOp(op)) throw SqlError.syntax();
    }

    private String expectIdent() {
        Token t = next();
        if (t.kind() != Token.Kind.IDENT) throw SqlError.syntax();
        return t.text();
    }

    // ---- statements ----

    private Stmt statement() {
        Token t = peek();
        if (t.isKeyword("CREATE")) return createTable();
        if (t.isKeyword("DROP")) return dropTable();
        if (t.isKeyword("INSERT")) return insert();
        if (t.isKeyword("SELECT")) return select();
        throw SqlError.syntax();
    }

    private Stmt createTable() {
        expectKeyword("CREATE");
        expectKeyword("TABLE");
        boolean ifNotExists = false;
        if (acceptKeyword("IF")) {
            expectKeyword("NOT");
            expectKeyword("EXISTS");
            ifNotExists = true;
        }
        String name = expectIdent();
        expectOp("(");
        List<Stmt.ColumnDef> cols = new ArrayList<>();
        do {
            String col = expectIdent();
            ColType type = ColType.parse(expectIdent());
            if (type == null) throw SqlError.syntax();
            cols.add(new Stmt.ColumnDef(col, type));
        } while (acceptOp(","));
        expectOp(")");
        return new Stmt.CreateTable(name, ifNotExists, cols);
    }

    private Stmt dropTable() {
        expectKeyword("DROP");
        expectKeyword("TABLE");
        boolean ifExists = false;
        if (acceptKeyword("IF")) {
            expectKeyword("EXISTS");
            ifExists = true;
        }
        return new Stmt.DropTable(expectIdent(), ifExists);
    }

    private Stmt insert() {
        expectKeyword("INSERT");
        expectKeyword("INTO");
        String table = expectIdent();
        List<String> columns = null;
        if (acceptOp("(")) {
            columns = new ArrayList<>();
            do {
                columns.add(expectIdent());
            } while (acceptOp(","));
            expectOp(")");
        }
        expectKeyword("VALUES");
        List<List<Expr>> rows = new ArrayList<>();
        do {
            expectOp("(");
            List<Expr> row = new ArrayList<>();
            do {
                row.add(expr());
            } while (acceptOp(","));
            expectOp(")");
            rows.add(row);
        } while (acceptOp(","));
        return new Stmt.Insert(table, columns, rows);
    }

    private Stmt select() {
        expectKeyword("SELECT");
        List<Stmt.ResultColumn> cols = new ArrayList<>();
        do {
            cols.add(resultColumn());
        } while (acceptOp(","));
        String from = acceptKeyword("FROM") ? expectIdent() : null;
        Expr where = acceptKeyword("WHERE") ? expr() : null;
        List<Stmt.OrderTerm> order = new ArrayList<>();
        if (acceptKeyword("ORDER")) {
            expectKeyword("BY");
            do {
                order.add(orderTerm());
            } while (acceptOp(","));
        }
        Expr limit = null;
        Expr offset = null;
        if (acceptKeyword("LIMIT")) {
            limit = expr();
            if (acceptKeyword("OFFSET")) offset = expr();
        }
        return new Stmt.Select(cols, from, where, order, limit, offset);
    }

    private Stmt.ResultColumn resultColumn() {
        if (acceptOp("*")) return new Stmt.ResultColumn(true, null, null);
        Expr e = expr();
        String alias = null;
        if (acceptKeyword("AS")) alias = expectIdent();
        else if (peek().kind() == Token.Kind.IDENT) alias = next().text();
        return new Stmt.ResultColumn(false, e, alias);
    }

    private Stmt.OrderTerm orderTerm() {
        Expr e = expr();
        boolean desc = false;
        if (acceptKeyword("DESC")) desc = true;
        else acceptKeyword("ASC");
        Boolean nullsFirst = null;
        if (acceptKeyword("NULLS")) {
            if (acceptKeyword("FIRST")) nullsFirst = true;
            else if (acceptKeyword("LAST")) nullsFirst = false;
            else throw SqlError.syntax();
        }
        return new Stmt.OrderTerm(e, desc, nullsFirst);
    }

    // ---- expressions, loosest binding first ----

    Expr expr() {
        return or();
    }

    private Expr or() {
        Expr l = and();
        while (acceptKeyword("OR")) l = new Expr.Binary(Expr.BinOp.OR, l, and());
        return l;
    }

    private Expr and() {
        Expr l = not();
        while (acceptKeyword("AND")) l = new Expr.Binary(Expr.BinOp.AND, l, not());
        return l;
    }

    private Expr not() {
        if (acceptKeyword("NOT")) return new Expr.Not(not());
        return equality();
    }

    private Expr equality() {
        Expr l = comparison();
        while (true) {
            Expr.BinOp op;
            if (acceptOp("=") || acceptOp("==")) op = Expr.BinOp.EQ;
            else if (acceptOp("!=") || acceptOp("<>")) op = Expr.BinOp.NE;
            else if (acceptKeyword("IS")) op = acceptKeyword("NOT") ? Expr.BinOp.ISNOT : Expr.BinOp.IS;
            else return l;
            l = new Expr.Binary(op, l, comparison());
        }
    }

    private Expr comparison() {
        Expr l = additive();
        while (true) {
            Expr.BinOp op;
            if (acceptOp("<")) op = Expr.BinOp.LT;
            else if (acceptOp("<=")) op = Expr.BinOp.LE;
            else if (acceptOp(">")) op = Expr.BinOp.GT;
            else if (acceptOp(">=")) op = Expr.BinOp.GE;
            else return l;
            l = new Expr.Binary(op, l, additive());
        }
    }

    private Expr additive() {
        Expr l = multiplicative();
        while (true) {
            Expr.BinOp op;
            if (acceptOp("+")) op = Expr.BinOp.ADD;
            else if (acceptOp("-")) op = Expr.BinOp.SUB;
            else return l;
            l = new Expr.Binary(op, l, multiplicative());
        }
    }

    private Expr multiplicative() {
        Expr l = concat();
        while (true) {
            Expr.BinOp op;
            if (acceptOp("*")) op = Expr.BinOp.MUL;
            else if (acceptOp("/")) op = Expr.BinOp.DIV;
            else if (acceptOp("%")) op = Expr.BinOp.MOD;
            else return l;
            l = new Expr.Binary(op, l, concat());
        }
    }

    private Expr concat() {
        Expr l = unary();
        while (acceptOp("||")) l = new Expr.Binary(Expr.BinOp.CONCAT, l, unary());
        return l;
    }

    private Expr unary() {
        if (acceptOp("-")) return new Expr.Unary('-', unary());
        if (acceptOp("+")) return new Expr.Unary('+', unary());
        return primary();
    }

    private Expr primary() {
        Token t = next();
        switch (t.kind()) {
            case NUMBER:
                return new Expr.Literal(t.value());
            case STRING:
                return new Expr.Literal(t.text());
            case KEYWORD:
                if (t.text().equals("NULL")) return new Expr.Literal(null);
                throw SqlError.syntax();
            case IDENT:
                return nameOrCall(t.text());
            case OP:
                if (t.text().equals("(")) {
                    Expr e = expr();
                    expectOp(")");
                    return e;
                }
                throw SqlError.syntax();
            default:
                throw SqlError.syntax();
        }
    }

    private Expr nameOrCall(String name) {
        if (acceptOp("(")) {
            List<Expr> args = new ArrayList<>();
            if (!acceptOp(")")) {
                do {
                    args.add(expr());
                } while (acceptOp(","));
                expectOp(")");
            }
            return new Expr.Call(name, args);
        }
        if (acceptOp(".")) return new Expr.Name(name, expectIdent());
        return new Expr.Name(null, name);
    }
}
