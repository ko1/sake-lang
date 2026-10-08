package sqlengine.parse;

import java.util.ArrayList;
import java.util.List;
import sqlengine.parse.Ast.*;
import sqlengine.parse.Token.Kind;
import sqlengine.value.Names;
import sqlengine.value.SqlType;

/** Recursive-descent parser for one statement (tokens without the terminating ';'). */
public final class Parser {
    private final List<Token> toks;
    private int i = 0;

    private Parser(List<Token> toks) {
        this.toks = toks;
    }

    /** Splits a script's tokens at ';' and parses each statement; a failure is kept as a SqlError. */
    public static List<Object> parseScript(List<Token> all) {
        List<Object> result = new ArrayList<>(); // Stmt or SqlError
        List<Token> cur = new ArrayList<>();
        for (Token t : all) {
            if (t.isOp(";")) {
                flush(cur, result);
                cur = new ArrayList<>();
            } else {
                cur.add(t);
            }
        }
        flush(cur, result);
        return result;
    }

    private static void flush(List<Token> cur, List<Object> result) {
        if (cur.isEmpty()) return;
        try {
            result.add(new Parser(cur).statement());
        } catch (SqlError e) {
            result.add(e);
        }
    }

    // ---- token helpers ----
    private Token peek() {
        return i < toks.size() ? toks.get(i) : new Token(Kind.EOF, "", null);
    }

    private Token next() {
        Token t = peek();
        i++;
        return t;
    }

    private boolean acceptKw(String kw) {
        if (peek().isKeyword(kw)) {
            i++;
            return true;
        }
        return false;
    }

    private boolean acceptOp(String op) {
        if (peek().isOp(op)) {
            i++;
            return true;
        }
        return false;
    }

    private void expectKw(String kw) {
        if (!acceptKw(kw)) throw SqlError.syntax();
    }

    private void expectOp(String op) {
        if (!acceptOp(op)) throw SqlError.syntax();
    }

    private String ident() {
        Token t = next();
        if (t.kind() != Kind.IDENT) throw SqlError.syntax();
        return t.text();
    }

    // ---- statements ----
    private Stmt statement() {
        Stmt s;
        if (acceptKw("CREATE")) s = createTable();
        else if (acceptKw("DROP")) s = dropTable();
        else if (acceptKw("INSERT")) s = insert();
        else if (acceptKw("SELECT")) s = select();
        else if (acceptKw("UPDATE")) s = update();
        else if (acceptKw("DELETE")) s = delete();
        else throw SqlError.syntax();
        if (peek().kind() != Kind.EOF) throw SqlError.syntax();
        return s;
    }

    private Stmt createTable() {
        expectKw("TABLE");
        boolean ifNotExists = false;
        if (acceptKw("IF")) {
            expectKw("NOT");
            expectKw("EXISTS");
            ifNotExists = true;
        }
        String name = ident();
        expectOp("(");
        List<ColumnDef> cols = new ArrayList<>();
        List<TableConstraint> constraints = new ArrayList<>();
        do {
            if (peek().isKeyword("PRIMARY") || peek().isKeyword("UNIQUE")) {
                constraints.add(tableConstraint());
            } else if (!constraints.isEmpty()) {
                throw SqlError.syntax(); // table constraints come after all column definitions
            } else {
                String col = ident();
                cols.add(new ColumnDef(col, type(), columnConstraints()));
            }
        } while (acceptOp(","));
        expectOp(")");
        return new CreateTable(name, ifNotExists, cols, constraints);
    }

    private TableConstraint tableConstraint() {
        boolean primary = acceptKw("PRIMARY");
        if (primary) expectKw("KEY");
        else expectKw("UNIQUE");
        expectOp("(");
        List<String> names = new ArrayList<>();
        do {
            names.add(ident());
        } while (acceptOp(","));
        expectOp(")");
        return new TableConstraint(primary, names);
    }

    private List<ColumnConstraint> columnConstraints() {
        List<ColumnConstraint> list = new ArrayList<>();
        while (true) {
            if (acceptKw("PRIMARY")) {
                expectKw("KEY");
                list.add(new ColumnConstraint(ConstraintKind.PRIMARY_KEY, null));
            } else if (acceptKw("NOT")) {
                expectKw("NULL");
                list.add(new ColumnConstraint(ConstraintKind.NOT_NULL, null));
            } else if (acceptKw("UNIQUE")) {
                list.add(new ColumnConstraint(ConstraintKind.UNIQUE, null));
            } else if (acceptKw("DEFAULT")) {
                list.add(new ColumnConstraint(ConstraintKind.DEFAULT, defaultValue()));
            } else {
                return list;
            }
        }
    }

    /** [+|-] numeric-literal | string-literal | NULL */
    private Object defaultValue() {
        boolean neg = false;
        boolean signed = false;
        if (peek().isOp("-") || peek().isOp("+")) {
            neg = next().text().equals("-");
            signed = true;
        }
        Token t = next();
        if (t.kind() == Kind.NUMBER) {
            Object v = t.value();
            if (!neg) return v;
            return v instanceof Long l ? (Object) (-l) : (Object) (-(Double) v);
        }
        if (!signed && t.kind() == Kind.STRING) return t.text();
        if (!signed && t.isKeyword("NULL")) return null;
        throw SqlError.syntax();
    }

    private SqlType type() {
        Token t = next();
        if (t.kind() == Kind.IDENT) {
            switch (Names.norm(t.text())) {
                case "integer": return SqlType.INTEGER;
                case "real": return SqlType.REAL;
                case "text": return SqlType.TEXT;
                default: break;
            }
        }
        throw SqlError.syntax();
    }

    private Stmt dropTable() {
        expectKw("TABLE");
        boolean ifExists = false;
        if (acceptKw("IF")) {
            expectKw("EXISTS");
            ifExists = true;
        }
        return new DropTable(ident(), ifExists);
    }

    private Stmt insert() {
        expectKw("INTO");
        String table = ident();
        List<String> cols = null;
        if (acceptOp("(")) {
            cols = new ArrayList<>();
            do {
                cols.add(ident());
            } while (acceptOp(","));
            expectOp(")");
        }
        expectKw("VALUES");
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
        return new Insert(table, cols, rows);
    }

    private Stmt update() {
        String table = ident();
        expectKw("SET");
        List<Assignment> sets = new ArrayList<>();
        do {
            String col = ident();
            expectOp("=");
            sets.add(new Assignment(col, expr()));
        } while (acceptOp(","));
        Expr where = acceptKw("WHERE") ? expr() : null;
        return new Update(table, sets, where);
    }

    private Stmt delete() {
        expectKw("FROM");
        String table = ident();
        Expr where = acceptKw("WHERE") ? expr() : null;
        return new Delete(table, where);
    }

    private Stmt select() {
        boolean distinct = acceptKw("DISTINCT");
        if (!distinct) acceptKw("ALL");
        List<ResultColumn> cols = new ArrayList<>();
        do {
            cols.add(resultColumn());
        } while (acceptOp(","));
        String from = null;
        if (acceptKw("FROM")) from = ident();
        Expr where = null;
        if (acceptKw("WHERE")) where = expr();
        List<Expr> groupBy = new ArrayList<>();
        if (acceptKw("GROUP")) {
            expectKw("BY");
            do {
                groupBy.add(expr());
            } while (acceptOp(","));
        }
        Expr having = acceptKw("HAVING") ? expr() : null;
        List<OrderTerm> order = orderBy();
        Expr limit = null;
        Expr offset = null;
        if (acceptKw("LIMIT")) {
            limit = expr();
            if (acceptKw("OFFSET")) offset = expr();
        }
        return new Select(distinct, cols, from, where, groupBy, having, order, limit, offset);
    }

    private ResultColumn resultColumn() {
        if (acceptOp("*")) return new ResultColumn(null, null);
        Expr e = expr();
        String alias = null;
        if (acceptKw("AS")) alias = ident();
        else if (peek().kind() == Kind.IDENT) alias = next().text();
        return new ResultColumn(e, alias);
    }

    /** An optional ORDER BY clause (also used inside aggregate calls); empty when absent. */
    private List<OrderTerm> orderBy() {
        List<OrderTerm> order = new ArrayList<>();
        if (acceptKw("ORDER")) {
            expectKw("BY");
            do {
                order.add(orderTerm());
            } while (acceptOp(","));
        }
        return order;
    }

    private OrderTerm orderTerm() {
        Expr e = expr();
        boolean desc = false;
        if (acceptKw("DESC")) desc = true;
        else acceptKw("ASC");
        Boolean nullsFirst = null;
        if (acceptKw("NULLS")) {
            if (acceptKw("FIRST")) nullsFirst = true;
            else if (acceptKw("LAST")) nullsFirst = false;
            else throw SqlError.syntax();
        }
        return new OrderTerm(e, desc, nullsFirst);
    }

    // ---- expressions, loosest to tightest ----
    public Expr expr() {
        return or();
    }

    private Expr or() {
        Expr l = and();
        while (acceptKw("OR")) l = new Binary("OR", l, and());
        return l;
    }

    private Expr and() {
        Expr l = not();
        while (acceptKw("AND")) l = new Binary("AND", l, not());
        return l;
    }

    private Expr not() {
        if (acceptKw("NOT")) return new Unary("NOT", not());
        return equality();
    }

    private Expr equality() {
        Expr l = relational();
        while (true) {
            Token t = peek();
            if (t.kind() == Kind.OP && (t.text().equals("=") || t.text().equals("=="))) {
                i++;
                l = new Binary("=", l, relational());
            } else if (t.kind() == Kind.OP && (t.text().equals("!=") || t.text().equals("<>"))) {
                i++;
                l = new Binary("!=", l, relational());
            } else if (t.isKeyword("IS")) {
                i++;
                boolean neg = acceptKw("NOT");
                l = new Is(l, relational(), neg);
            } else if (isMembershipKeyword(t) || (t.isKeyword("NOT") && isMembershipKeyword(peekAt(1)))) {
                boolean neg = acceptKw("NOT");
                l = membership(l, neg);
            } else {
                return l;
            }
        }
    }

    private static boolean isMembershipKeyword(Token t) {
        return t.isKeyword("IN") || t.isKeyword("LIKE") || t.isKeyword("BETWEEN");
    }

    private Token peekAt(int offset) {
        return i + offset < toks.size() ? toks.get(i + offset) : new Token(Kind.EOF, "", null);
    }

    /** The rest of "x [NOT] IN (...)", "x [NOT] LIKE p" or "x [NOT] BETWEEN a AND b" after x (and NOT). */
    private Expr membership(Expr x, boolean negated) {
        if (acceptKw("LIKE")) return new Like(x, relational(), negated);
        if (acceptKw("BETWEEN")) {
            Expr low = relational();
            expectKw("AND");
            return new Between(x, low, relational(), negated);
        }
        expectKw("IN");
        expectOp("(");
        List<Expr> items = new ArrayList<>();
        if (!acceptOp(")")) {
            do {
                items.add(expr());
            } while (acceptOp(","));
            expectOp(")");
        }
        return new In(x, items, negated);
    }

    private Expr relational() {
        Expr l = additive();
        while (true) {
            Token t = peek();
            if (t.kind() == Kind.OP && (t.text().equals("<") || t.text().equals("<=")
                    || t.text().equals(">") || t.text().equals(">="))) {
                i++;
                l = new Binary(t.text(), l, additive());
            } else {
                return l;
            }
        }
    }

    private Expr additive() {
        Expr l = multiplicative();
        while (peek().isOp("+") || peek().isOp("-")) {
            String op = next().text();
            l = new Binary(op, l, multiplicative());
        }
        return l;
    }

    private Expr multiplicative() {
        Expr l = concat();
        while (peek().isOp("*") || peek().isOp("/") || peek().isOp("%")) {
            String op = next().text();
            l = new Binary(op, l, concat());
        }
        return l;
    }

    private Expr concat() {
        Expr l = unary();
        while (acceptOp("||")) l = new Binary("||", l, unary());
        return l;
    }

    private Expr unary() {
        if (acceptOp("-")) return new Unary("-", unary());
        if (acceptOp("+")) return new Unary("+", unary());
        return primary();
    }

    private Expr primary() {
        Token t = next();
        switch (t.kind()) {
            case NUMBER:
                return new Literal(t.value());
            case STRING:
                return new Literal(t.text());
            case KEYWORD:
                if (t.text().equals("NULL")) return new Literal(null);
                if (t.text().equals("CASE")) return caseExpr();
                if (t.text().equals("CAST")) return cast();
                throw SqlError.syntax();
            case IDENT:
                if (acceptOp("(")) return call(t.text());
                return new Name(t.text());
            case OP:
                if (t.text().equals("(")) {
                    Expr e = expr();
                    expectOp(")");
                    return e; // parentheses are transparent (column affinity survives them)
                }
                throw SqlError.syntax();
            default:
                throw SqlError.syntax();
        }
    }

    /** The rest of a call after "name(": "*", or [DISTINCT] arguments [ORDER BY ...]. */
    private Expr call(String name) {
        List<Expr> args = new ArrayList<>();
        if (acceptOp("*")) {
            expectOp(")");
            return new Call(name, args, true, false, List.of());
        }
        if (acceptOp(")")) return new Call(name, args);
        boolean distinct = acceptKw("DISTINCT");
        do {
            args.add(expr());
        } while (acceptOp(","));
        List<OrderTerm> order = orderBy();
        expectOp(")");
        return new Call(name, args, false, distinct, order);
    }

    private Expr caseExpr() {
        Expr operand = peek().isKeyword("WHEN") ? null : expr();
        List<When> whens = new ArrayList<>();
        do {
            expectKw("WHEN");
            Expr cond = expr();
            expectKw("THEN");
            whens.add(new When(cond, expr()));
        } while (peek().isKeyword("WHEN"));
        Expr elseResult = acceptKw("ELSE") ? expr() : null;
        expectKw("END");
        return new Case(operand, whens, elseResult);
    }

    private Expr cast() {
        expectOp("(");
        Expr x = expr();
        expectKw("AS");
        SqlType type = type();
        expectOp(")");
        return new Cast(x, type);
    }
}
