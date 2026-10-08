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
        if (acceptKw("CREATE")) s = create();
        else if (acceptKw("DROP")) s = drop();
        else if (acceptKw("ALTER")) s = alterTable();
        else if (acceptKw("INSERT")) s = insert(null);
        else if (peek().isKeyword("SELECT")) s = query(null);
        else if (peek().isKeyword("WITH")) {
            With with = with();
            s = acceptKw("INSERT") ? insert(with) : query(with);
        } else if (acceptKw("UPDATE")) s = update();
        else if (acceptKw("DELETE")) s = delete();
        else if (acceptKw("BEGIN")) s = transaction(TransactionOp.BEGIN);
        else if (acceptKw("COMMIT") || acceptKw("END")) s = transaction(TransactionOp.COMMIT);
        else if (acceptKw("ROLLBACK")) s = transaction(TransactionOp.ROLLBACK);
        else throw SqlError.syntax();
        if (peek().kind() != Kind.EOF) throw SqlError.syntax();
        return s;
    }

    private Stmt transaction(TransactionOp op) {
        acceptKw("TRANSACTION");
        return new Transaction(op);
    }

    private Stmt create() {
        if (acceptKw("TABLE")) return createTable();
        if (acceptKw("VIEW")) return createView();
        boolean unique = acceptKw("UNIQUE");
        expectKw("INDEX");
        return createIndex(unique);
    }

    private boolean ifNotExists() {
        if (!acceptKw("IF")) return false;
        expectKw("NOT");
        expectKw("EXISTS");
        return true;
    }

    private boolean ifExists() {
        if (!acceptKw("IF")) return false;
        expectKw("EXISTS");
        return true;
    }

    /** ( name [, name]... ) */
    private List<String> nameList() {
        expectOp("(");
        List<String> names = new ArrayList<>();
        do {
            names.add(ident());
        } while (acceptOp(","));
        expectOp(")");
        return names;
    }

    private Stmt createView() {
        boolean ifNotExists = ifNotExists();
        String name = ident();
        List<String> columns = peek().isOp("(") ? nameList() : null;
        expectKw("AS");
        return new CreateView(name, ifNotExists, columns, query(null));
    }

    private Stmt createIndex(boolean unique) {
        boolean ifNotExists = ifNotExists();
        String name = ident();
        expectKw("ON");
        String table = ident();
        expectOp("(");
        List<String> columns = new ArrayList<>();
        List<String> collations = new ArrayList<>();
        do {
            columns.add(ident());
            collations.add(acceptKw("COLLATE") ? ident() : null);
        } while (acceptOp(","));
        expectOp(")");
        return new CreateIndex(name, unique, ifNotExists, table, columns, collations);
    }

    private Stmt drop() {
        if (acceptKw("TABLE")) return dropTable();
        if (acceptKw("VIEW")) {
            boolean ifExists = ifExists();
            return new DropView(ident(), ifExists);
        }
        expectKw("INDEX");
        boolean ifExists = ifExists();
        return new DropIndex(ident(), ifExists);
    }

    private Stmt alterTable() {
        expectKw("TABLE");
        String table = ident();
        if (acceptKw("ADD")) {
            acceptKw("COLUMN");
            String col = ident();
            return new AlterTable(table, new AddColumn(new ColumnDef(col, type(), columnConstraints())));
        }
        expectKw("RENAME");
        if (acceptKw("TO")) return new AlterTable(table, new RenameTable(ident()));
        acceptKw("COLUMN");
        String col = ident();
        expectKw("TO");
        return new AlterTable(table, new RenameColumn(col, ident()));
    }

    private Stmt createTable() {
        boolean ifNotExists = ifNotExists();
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
            } else if (acceptKw("COLLATE")) {
                list.add(new ColumnConstraint(ConstraintKind.COLLATE, ident()));
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
        boolean ifExists = ifExists();
        return new DropTable(ident(), ifExists);
    }

    /** The rest of INSERT after the keyword; with is the WITH clause before it, or null. */
    private Stmt insert(With with) {
        expectKw("INTO");
        String table = ident();
        List<String> cols = peek().isOp("(") ? nameList() : null;
        if (peek().isKeyword("SELECT") || peek().isKeyword("WITH")) {
            return new Insert(table, cols, null, withFirst(with, query(null)));
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
        return new Insert(table, cols, rows, null);
    }

    /** sel with the ctes of an enclosing WITH put before its own. */
    private static Select withFirst(With outer, Select sel) {
        if (outer == null) return sel;
        List<Cte> all = new ArrayList<>(outer.ctes());
        boolean recursive = outer.recursive();
        if (sel.with() != null) {
            all.addAll(sel.with().ctes());
            recursive |= sel.with().recursive();
        }
        return new Select(new With(recursive, all), sel.first(), sel.rest(), sel.orderBy(), sel.limit(), sel.offset());
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

    private With with() {
        expectKw("WITH");
        boolean recursive = acceptKw("RECURSIVE");
        List<Cte> ctes = new ArrayList<>();
        do {
            String name = ident();
            List<String> cols = peek().isOp("(") ? nameList() : null;
            expectKw("AS");
            expectOp("(");
            Select sel = query(null);
            expectOp(")");
            ctes.add(new Cte(name, cols, sel));
        } while (acceptOp(","));
        return new With(recursive, ctes);
    }

    /** A whole select (5.1); with is a WITH already read by the caller, else one is read here if present. */
    private Select query(With with) {
        if (with == null && peek().isKeyword("WITH")) with = with();
        SelectCore first = selectCore();
        List<CompoundTerm> rest = new ArrayList<>();
        while (true) {
            CompoundOp op;
            if (acceptKw("UNION")) op = acceptKw("ALL") ? CompoundOp.UNION_ALL : CompoundOp.UNION;
            else if (acceptKw("INTERSECT")) op = CompoundOp.INTERSECT;
            else if (acceptKw("EXCEPT")) op = CompoundOp.EXCEPT;
            else break;
            rest.add(new CompoundTerm(op, selectCore()));
        }
        List<OrderTerm> order = orderBy();
        Expr limit = null;
        Expr offset = null;
        if (acceptKw("LIMIT")) {
            limit = expr();
            if (acceptKw("OFFSET")) offset = expr();
        }
        return new Select(with, first, rest, order, limit, offset);
    }

    private SelectCore selectCore() {
        expectKw("SELECT");
        boolean distinct = acceptKw("DISTINCT");
        if (!distinct) acceptKw("ALL");
        List<ResultColumn> cols = new ArrayList<>();
        do {
            cols.add(resultColumn());
        } while (acceptOp(","));
        FromClause from = null;
        if (acceptKw("FROM")) from = fromClause();
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
        List<NamedWindow> windows = new ArrayList<>();
        if (acceptKw("WINDOW")) {
            do {
                String name = ident();
                expectKw("AS");
                windows.add(new NamedWindow(name, windowSpec()));
            } while (acceptOp(","));
        }
        return new SelectCore(distinct, cols, from, where, groupBy, having, windows);
    }

    /** ( [base] [PARTITION BY ...] [ORDER BY ...] [frame] ) */
    private WindowSpec windowSpec() {
        expectOp("(");
        String base = peek().kind() == Kind.IDENT ? next().text() : null;
        List<Expr> partition = new ArrayList<>();
        if (acceptKw("PARTITION")) {
            expectKw("BY");
            do {
                partition.add(expr());
            } while (acceptOp(","));
        }
        List<OrderTerm> order = orderBy();
        FrameSpec frame = peek().isKeyword("ROWS") || peek().isKeyword("RANGE") ? frameSpec() : null;
        expectOp(")");
        return new WindowSpec(base, partition, order, frame);
    }

    private FrameSpec frameSpec() {
        FrameMode mode = next().text().equals("ROWS") ? FrameMode.ROWS : FrameMode.RANGE;
        if (!acceptKw("BETWEEN")) return new FrameSpec(mode, frameBound(true), new FrameBound(BoundKind.CURRENT_ROW, null));
        FrameBound start = frameBound(true);
        expectKw("AND");
        return new FrameSpec(mode, start, frameBound(false));
    }

    /** A frame boundary; "UNBOUNDED FOLLOWING" cannot start a frame nor "UNBOUNDED PRECEDING" end one. */
    private FrameBound frameBound(boolean isStart) {
        if (acceptKw("UNBOUNDED")) {
            if (isStart) {
                expectKw("PRECEDING");
                return new FrameBound(BoundKind.UNBOUNDED_PRECEDING, null);
            }
            expectKw("FOLLOWING");
            return new FrameBound(BoundKind.UNBOUNDED_FOLLOWING, null);
        }
        if (acceptKw("CURRENT")) {
            expectKw("ROW");
            return new FrameBound(BoundKind.CURRENT_ROW, null);
        }
        boolean neg = acceptOp("-");
        if (!neg) acceptOp("+");
        Token t = next();
        if (t.kind() != Kind.NUMBER) throw SqlError.syntax();
        Number n = (Number) t.value();
        if (neg) n = n instanceof Long l ? (Number) (-l) : (Number) (-n.doubleValue());
        if (acceptKw("PRECEDING")) return new FrameBound(BoundKind.PRECEDING, n);
        expectKw("FOLLOWING");
        return new FrameBound(BoundKind.FOLLOWING, n);
    }

    private boolean atQuery() {
        return peek().isKeyword("SELECT") || peek().isKeyword("WITH");
    }

    private FromClause fromClause() {
        FromItem first = fromItem();
        List<JoinStep> joins = new ArrayList<>();
        while (true) {
            JoinKind kind;
            if (acceptOp(",")) {
                joins.add(new JoinStep(JoinKind.CROSS, fromItem(), null, List.of()));
                continue;
            } else if (acceptKw("CROSS")) {
                expectKw("JOIN");
                joins.add(new JoinStep(JoinKind.CROSS, fromItem(), null, List.of()));
                continue;
            } else if (acceptKw("LEFT")) {
                acceptKw("OUTER");
                expectKw("JOIN");
                kind = JoinKind.LEFT;
            } else if (acceptKw("INNER")) {
                expectKw("JOIN");
                kind = JoinKind.INNER;
            } else if (acceptKw("JOIN")) {
                kind = JoinKind.INNER;
            } else {
                return new FromClause(first, joins);
            }
            FromItem item = fromItem();
            Expr on = null;
            List<String> using = List.of();
            if (acceptKw("ON")) {
                on = expr();
            } else if (acceptKw("USING")) {
                expectOp("(");
                using = new ArrayList<>();
                do {
                    using.add(ident());
                } while (acceptOp(","));
                expectOp(")");
            } else if (kind == JoinKind.LEFT) {
                throw SqlError.syntax();
            }
            joins.add(new JoinStep(kind, item, on, using));
        }
    }

    private FromItem fromItem() {
        if (acceptOp("(")) {
            Select sub = query(null);
            expectOp(")");
            return new SubqueryRef(sub, optionalAlias());
        }
        return new TableRef(ident(), optionalAlias());
    }

    private String optionalAlias() {
        if (acceptKw("AS")) return ident();
        return peek().kind() == Kind.IDENT ? next().text() : null;
    }

    private ResultColumn resultColumn() {
        if (acceptOp("*")) return new ResultColumn(null, null);
        if (peek().kind() == Kind.IDENT && peekAt(1).isOp(".") && peekAt(2).isOp("*")) {
            String q = next().text();
            i += 2;
            return new ResultColumn(null, null, q);
        }
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
        if (atQuery()) {
            Select sub = query(null);
            expectOp(")");
            return new InSelect(x, sub, negated);
        }
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
        return collated(primary());
    }

    /** Postfix "e COLLATE name" binds tighter than every binary operator (7.2). */
    private Expr collated(Expr e) {
        while (acceptKw("COLLATE")) e = new Collate(e, ident());
        return e;
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
                if (t.text().equals("EXISTS")) {
                    expectOp("(");
                    Select sub = query(null);
                    expectOp(")");
                    return new Exists(sub, false);
                }
                throw SqlError.syntax();
            case IDENT:
                if (acceptOp("(")) return call(t.text());
                if (acceptOp(".")) return new Name(t.text(), ident());
                return new Name(t.text());
            case OP:
                if (t.text().equals("(")) {
                    if (atQuery()) {
                        Select sub = query(null);
                        expectOp(")");
                        return new Subquery(sub);
                    }
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
            return overClause(new Call(name, args, true, false, List.of()));
        }
        if (acceptOp(")")) return overClause(new Call(name, args));
        boolean distinct = acceptKw("DISTINCT");
        do {
            args.add(expr());
        } while (acceptOp(","));
        List<OrderTerm> order = orderBy();
        expectOp(")");
        return overClause(new Call(name, args, false, distinct, order));
    }

    /** A call followed by OVER becomes a window call: OVER name, or OVER ( window-spec ). */
    private Expr overClause(Call call) {
        if (!acceptKw("OVER")) return call;
        if (peek().kind() == Kind.IDENT) {
            return new WindowCall(call, new WindowSpec(next().text(), List.of(), List.of(), null));
        }
        return new WindowCall(call, windowSpec());
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
