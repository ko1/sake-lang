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
        if (t.isKeyword("UPDATE")) return update();
        if (t.isKeyword("DELETE")) return delete();
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
        List<Stmt.TableConstraint> constraints = new ArrayList<>();
        do {
            if (peek().isKeyword("PRIMARY") || peek().isKeyword("UNIQUE")) {
                constraints.add(tableConstraint());
            } else {
                if (!constraints.isEmpty()) throw SqlError.syntax();
                cols.add(columnDef());
            }
        } while (acceptOp(","));
        expectOp(")");
        return new Stmt.CreateTable(name, ifNotExists, cols, constraints);
    }

    private Stmt.ColumnDef columnDef() {
        String col = expectIdent();
        ColType type = ColType.parse(expectIdent());
        if (type == null) throw SqlError.syntax();
        boolean notNull = false;
        boolean primary = false;
        boolean unique = false;
        Object dflt = null;
        while (true) {
            if (acceptKeyword("PRIMARY")) {
                expectKeyword("KEY");
                primary = true;
            } else if (acceptKeyword("NOT")) {
                expectKeyword("NULL");
                notNull = true;
            } else if (acceptKeyword("UNIQUE")) {
                unique = true;
            } else if (acceptKeyword("DEFAULT")) {
                dflt = defaultValue();
            } else {
                return new Stmt.ColumnDef(col, type, notNull, primary, unique, dflt);
            }
        }
    }

    /** [+|-] numeric literal, string literal or NULL. */
    private Object defaultValue() {
        boolean neg = false;
        boolean signed = false;
        if (acceptOp("-")) {
            neg = signed = true;
        } else if (acceptOp("+")) {
            signed = true;
        }
        Token t = next();
        if (t.kind() == Token.Kind.NUMBER) {
            Object v = t.value();
            if (!neg) return v;
            return v instanceof Long l ? (Object) (-l) : (Object) (-(Double) v);
        }
        if (signed) throw SqlError.syntax();
        if (t.kind() == Token.Kind.STRING) return t.text();
        if (t.isKeyword("NULL")) return null;
        throw SqlError.syntax();
    }

    private Stmt.TableConstraint tableConstraint() {
        boolean primary = acceptKeyword("PRIMARY");
        if (primary) expectKeyword("KEY");
        else expectKeyword("UNIQUE");
        expectOp("(");
        List<String> cols = new ArrayList<>();
        do {
            cols.add(expectIdent());
        } while (acceptOp(","));
        expectOp(")");
        return new Stmt.TableConstraint(primary, cols);
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

    private Stmt update() {
        expectKeyword("UPDATE");
        String table = expectIdent();
        expectKeyword("SET");
        List<Stmt.Assignment> sets = new ArrayList<>();
        do {
            String col = expectIdent();
            expectOp("=");
            sets.add(new Stmt.Assignment(col, expr()));
        } while (acceptOp(","));
        Expr where = acceptKeyword("WHERE") ? expr() : null;
        return new Stmt.Update(table, sets, where);
    }

    private Stmt delete() {
        expectKeyword("DELETE");
        expectKeyword("FROM");
        String table = expectIdent();
        Expr where = acceptKeyword("WHERE") ? expr() : null;
        return new Stmt.Delete(table, where);
    }

    private Stmt select() {
        expectKeyword("SELECT");
        boolean distinct = acceptKeyword("DISTINCT");
        if (!distinct) acceptKeyword("ALL");
        List<Stmt.ResultColumn> cols = new ArrayList<>();
        do {
            cols.add(resultColumn());
        } while (acceptOp(","));
        String from = acceptKeyword("FROM") ? expectIdent() : null;
        Expr where = acceptKeyword("WHERE") ? expr() : null;
        List<Expr> groupBy = new ArrayList<>();
        if (acceptKeyword("GROUP")) {
            expectKeyword("BY");
            do {
                groupBy.add(expr());
            } while (acceptOp(","));
        }
        Expr having = acceptKeyword("HAVING") ? expr() : null;
        List<Stmt.OrderTerm> order = orderBy();
        Expr limit = null;
        Expr offset = null;
        if (acceptKeyword("LIMIT")) {
            limit = expr();
            if (acceptKeyword("OFFSET")) offset = expr();
        }
        return new Stmt.Select(distinct, cols, from, where, groupBy, having, order, limit, offset);
    }

    /** [ORDER BY term, ...]: empty when absent. */
    private List<Stmt.OrderTerm> orderBy() {
        List<Stmt.OrderTerm> order = new ArrayList<>();
        if (acceptKeyword("ORDER")) {
            expectKeyword("BY");
            do {
                order.add(orderTerm());
            } while (acceptOp(","));
        }
        return order;
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
            Expr predicate = predicate(l);
            if (predicate != null) {
                l = predicate;
                continue;
            }
            Expr.BinOp op;
            if (acceptOp("=") || acceptOp("==")) op = Expr.BinOp.EQ;
            else if (acceptOp("!=") || acceptOp("<>")) op = Expr.BinOp.NE;
            else if (acceptKeyword("IS")) op = acceptKeyword("NOT") ? Expr.BinOp.ISNOT : Expr.BinOp.IS;
            else return l;
            l = new Expr.Binary(op, l, comparison());
        }
    }

    /** [NOT] IN / LIKE / BETWEEN after operand l (same level as '='), or null (nothing consumed) if none. */
    private Expr predicate(Expr l) {
        int save = p;
        boolean negated = acceptKeyword("NOT");
        if (acceptKeyword("IN")) {
            expectOp("(");
            List<Expr> items = new ArrayList<>();
            if (!acceptOp(")")) {
                do {
                    items.add(expr());
                } while (acceptOp(","));
                expectOp(")");
            }
            return new Expr.In(l, items, negated);
        }
        if (acceptKeyword("LIKE")) return new Expr.Like(l, comparison(), negated);
        if (acceptKeyword("BETWEEN")) {
            Expr low = comparison();
            expectKeyword("AND");
            return new Expr.Between(l, low, comparison(), negated);
        }
        p = save;
        return null;
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
                if (t.text().equals("CASE")) return caseExpr();
                if (t.text().equals("CAST")) return cast();
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

    private Expr caseExpr() {
        Expr base = peek().isKeyword("WHEN") ? null : expr();
        List<Expr.When> whens = new ArrayList<>();
        do {
            expectKeyword("WHEN");
            Expr cond = expr();
            expectKeyword("THEN");
            whens.add(new Expr.When(cond, expr()));
        } while (peek().isKeyword("WHEN"));
        Expr otherwise = acceptKeyword("ELSE") ? expr() : null;
        expectKeyword("END");
        return new Expr.Case(base, whens, otherwise);
    }

    private Expr cast() {
        expectOp("(");
        Expr operand = expr();
        expectKeyword("AS");
        ColType type = ColType.parse(expectIdent());
        if (type == null) throw SqlError.syntax();
        expectOp(")");
        return new Expr.Cast(operand, type);
    }

    private Expr nameOrCall(String name) {
        if (acceptOp("(")) {
            List<Expr> args = new ArrayList<>();
            if (acceptOp("*")) {
                expectOp(")");
                return new Expr.Call(name, args, true, false, List.of());
            }
            boolean distinct = false;
            List<Stmt.OrderTerm> order = List.of();
            if (!acceptOp(")")) {
                distinct = acceptKeyword("DISTINCT");
                do {
                    args.add(expr());
                } while (acceptOp(","));
                order = orderBy();
                expectOp(")");
            }
            return new Expr.Call(name, args, false, distinct, order);
        }
        if (acceptOp(".")) return new Expr.Name(name, expectIdent());
        return new Expr.Name(null, name);
    }
}
