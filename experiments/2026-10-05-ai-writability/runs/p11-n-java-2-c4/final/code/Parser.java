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
        if (t.isKeyword("CREATE")) return create();
        if (t.isKeyword("DROP")) return drop();
        if (t.isKeyword("INSERT")) return insert(null);
        if (t.isKeyword("SELECT")) return select();
        if (t.isKeyword("WITH")) return withStatement();
        if (t.isKeyword("UPDATE")) return update();
        if (t.isKeyword("DELETE")) return delete();
        if (t.isKeyword("ALTER")) return alter();
        if (t.isKeyword("BEGIN")) {
            p++;
            acceptKeyword("TRANSACTION");
            return new Stmt.Begin();
        }
        if (t.isKeyword("COMMIT") || t.isKeyword("END")) {
            p++;
            acceptKeyword("TRANSACTION");
            return new Stmt.Commit();
        }
        if (t.isKeyword("ROLLBACK")) {
            p++;
            acceptKeyword("TRANSACTION");
            return new Stmt.Rollback();
        }
        throw SqlError.syntax();
    }

    /** WITH ... followed by a SELECT or an INSERT. */
    private Stmt withStatement() {
        Stmt.With with = with();
        if (peek().isKeyword("INSERT")) return insert(with);
        return select(with);
    }

    /** WITH [RECURSIVE] cte, ... */
    private Stmt.With with() {
        expectKeyword("WITH");
        boolean recursive = acceptKeyword("RECURSIVE");
        List<Stmt.Cte> ctes = new ArrayList<>();
        do {
            String name = expectIdent();
            List<String> columns = acceptOp("(") ? identList() : null;
            expectKeyword("AS");
            expectOp("(");
            Stmt.Select sel = select();
            expectOp(")");
            ctes.add(new Stmt.Cte(name, columns, sel));
        } while (acceptOp(","));
        return new Stmt.With(recursive, ctes);
    }

    /** name, name, ... ")" (the opening parenthesis is already consumed). */
    private List<String> identList() {
        List<String> names = new ArrayList<>();
        do {
            names.add(expectIdent());
        } while (acceptOp(","));
        expectOp(")");
        return names;
    }

    private Stmt create() {
        expectKeyword("CREATE");
        if (peek().isKeyword("TABLE")) return createTable();
        if (peek().isKeyword("VIEW")) return createView();
        boolean unique = acceptKeyword("UNIQUE");
        if (peek().isKeyword("INDEX")) return createIndex(unique);
        throw SqlError.syntax();
    }

    private Stmt drop() {
        expectKeyword("DROP");
        boolean table = peek().isKeyword("TABLE");
        boolean view = peek().isKeyword("VIEW");
        if (!table && !view && !peek().isKeyword("INDEX")) throw SqlError.syntax();
        p++;
        boolean ifExists = false;
        if (acceptKeyword("IF")) {
            expectKeyword("EXISTS");
            ifExists = true;
        }
        String name = expectIdent();
        if (table) return new Stmt.DropTable(name, ifExists);
        if (view) return new Stmt.DropView(name, ifExists);
        return new Stmt.DropIndex(name, ifExists);
    }

    /** IF NOT EXISTS, or nothing. */
    private boolean ifNotExists() {
        if (!acceptKeyword("IF")) return false;
        expectKeyword("NOT");
        expectKeyword("EXISTS");
        return true;
    }

    private Stmt createView() {
        expectKeyword("VIEW");
        boolean ifNotExists = ifNotExists();
        String name = expectIdent();
        List<String> columns = acceptOp("(") ? identList() : null;
        expectKeyword("AS");
        return new Stmt.CreateView(name, ifNotExists, columns, select());
    }

    private Stmt createIndex(boolean unique) {
        expectKeyword("INDEX");
        boolean ifNotExists = ifNotExists();
        String name = expectIdent();
        expectKeyword("ON");
        String table = expectIdent();
        expectOp("(");
        return new Stmt.CreateIndex(name, unique, ifNotExists, table, identList());
    }

    private Stmt alter() {
        expectKeyword("ALTER");
        expectKeyword("TABLE");
        String table = expectIdent();
        if (acceptKeyword("ADD")) {
            acceptKeyword("COLUMN");
            return new Stmt.AlterAddColumn(table, columnDef());
        }
        expectKeyword("RENAME");
        if (acceptKeyword("TO")) return new Stmt.AlterRenameTable(table, expectIdent());
        acceptKeyword("COLUMN");
        String column = expectIdent();
        expectKeyword("TO");
        return new Stmt.AlterRenameColumn(table, column, expectIdent());
    }

    private Stmt createTable() {
        expectKeyword("TABLE");
        boolean ifNotExists = ifNotExists();
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

    private Stmt insert(Stmt.With with) {
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
        if (peek().isKeyword("SELECT") || peek().isKeyword("WITH")) {
            return new Stmt.Insert(table, columns, null, select(), with);
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
        return new Stmt.Insert(table, columns, rows, null, with);
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

    /** A full select: [WITH] simple-select [compound-op simple-select]... [ORDER BY] [LIMIT [OFFSET]]. */
    private Stmt.Select select() {
        return select(peek().isKeyword("WITH") ? with() : null);
    }

    private Stmt.Select select(Stmt.With with) {
        Stmt.Core first = core();
        List<Stmt.CompoundPart> rest = new ArrayList<>();
        while (true) {
            Stmt.CompoundOp op;
            if (acceptKeyword("UNION")) op = acceptKeyword("ALL") ? Stmt.CompoundOp.UNION_ALL : Stmt.CompoundOp.UNION;
            else if (acceptKeyword("INTERSECT")) op = Stmt.CompoundOp.INTERSECT;
            else if (acceptKeyword("EXCEPT")) op = Stmt.CompoundOp.EXCEPT;
            else break;
            rest.add(new Stmt.CompoundPart(op, core()));
        }
        List<Stmt.OrderTerm> order = orderBy();
        Expr limit = null;
        Expr offset = null;
        if (acceptKeyword("LIMIT")) {
            limit = expr();
            if (acceptKeyword("OFFSET")) offset = expr();
        }
        return new Stmt.Select(with, first, rest, order, limit, offset);
    }

    private Stmt.Core core() {
        expectKeyword("SELECT");
        boolean distinct = acceptKeyword("DISTINCT");
        if (!distinct) acceptKeyword("ALL");
        List<Stmt.ResultColumn> cols = new ArrayList<>();
        do {
            cols.add(resultColumn());
        } while (acceptOp(","));
        Stmt.From from = acceptKeyword("FROM") ? from() : null;
        Expr where = acceptKeyword("WHERE") ? expr() : null;
        List<Expr> groupBy = new ArrayList<>();
        if (acceptKeyword("GROUP")) {
            expectKeyword("BY");
            do {
                groupBy.add(expr());
            } while (acceptOp(","));
        }
        Expr having = acceptKeyword("HAVING") ? expr() : null;
        List<Stmt.NamedWindow> windows = new ArrayList<>();
        if (acceptKeyword("WINDOW")) {
            do {
                String name = expectIdent();
                expectKeyword("AS");
                windows.add(new Stmt.NamedWindow(name, windowSpec()));
            } while (acceptOp(","));
        }
        return new Stmt.Core(distinct, cols, from, where, groupBy, having, windows);
    }

    private Stmt.From from() {
        Stmt.FromItem first = fromItem();
        List<Stmt.Join> joins = new ArrayList<>();
        while (true) {
            Stmt.JoinKind kind;
            if (acceptOp(",")) {
                kind = Stmt.JoinKind.CROSS;
            } else if (acceptKeyword("CROSS")) {
                expectKeyword("JOIN");
                kind = Stmt.JoinKind.CROSS;
            } else if (acceptKeyword("LEFT")) {
                acceptKeyword("OUTER");
                expectKeyword("JOIN");
                kind = Stmt.JoinKind.LEFT;
            } else if (acceptKeyword("INNER")) {
                expectKeyword("JOIN");
                kind = Stmt.JoinKind.INNER;
            } else if (acceptKeyword("JOIN")) {
                kind = Stmt.JoinKind.INNER;
            } else {
                return new Stmt.From(first, joins);
            }
            Stmt.FromItem item = fromItem();
            Expr on = null;
            List<String> using = null;
            if (kind != Stmt.JoinKind.CROSS) {
                if (acceptKeyword("ON")) {
                    on = expr();
                } else if (acceptKeyword("USING")) {
                    using = new ArrayList<>();
                    expectOp("(");
                    do {
                        using.add(expectIdent());
                    } while (acceptOp(","));
                    expectOp(")");
                } else if (kind == Stmt.JoinKind.LEFT) {
                    throw SqlError.syntax();
                }
            }
            joins.add(new Stmt.Join(kind, item, on, using));
        }
    }

    private Stmt.FromItem fromItem() {
        if (acceptOp("(")) {
            if (!peek().isKeyword("SELECT") && !peek().isKeyword("WITH")) throw SqlError.syntax();
            Stmt.Select sub = select();
            expectOp(")");
            return new Stmt.SubqueryRef(sub, optionalAlias());
        }
        String table = expectIdent();
        return new Stmt.TableRef(table, optionalAlias());
    }

    /** [AS] alias, or null. */
    private String optionalAlias() {
        if (acceptKeyword("AS")) return expectIdent();
        if (peek().kind() == Token.Kind.IDENT) return next().text();
        return null;
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
        if (acceptOp("*")) return new Stmt.ResultColumn(true, null, null, null);
        if (peek().kind() == Token.Kind.IDENT && p + 2 < toks.size() && toks.get(p + 1).isOp(".")
            && toks.get(p + 2).isOp("*")) {
            String table = next().text();
            p += 2;
            return new Stmt.ResultColumn(true, table, null, null);
        }
        return new Stmt.ResultColumn(false, null, expr(), optionalAlias());
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
            if (peek().isKeyword("SELECT") || peek().isKeyword("WITH")) {
                Stmt.Select sub = select();
                expectOp(")");
                return new Expr.InSelect(l, sub, negated);
            }
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
                if (t.text().equals("EXISTS")) {
                    expectOp("(");
                    Stmt.Select sub = select();
                    expectOp(")");
                    return new Expr.Exists(sub);
                }
                throw SqlError.syntax();
            case IDENT:
                return nameOrCall(t.text());
            case OP:
                if (t.text().equals("(")) {
                    if (peek().isKeyword("SELECT") || peek().isKeyword("WITH")) {
                        Stmt.Select sub = select();
                        expectOp(")");
                        return new Expr.Subquery(sub);
                    }
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

    /** ( [base] [PARTITION BY ...] [ORDER BY ...] [frame] ), with the parentheses. */
    private Stmt.WindowSpec windowSpec() {
        expectOp("(");
        String base = peek().kind() == Token.Kind.IDENT ? next().text() : null;
        List<Expr> partition = new ArrayList<>();
        if (acceptKeyword("PARTITION")) {
            expectKeyword("BY");
            do {
                partition.add(expr());
            } while (acceptOp(","));
        }
        List<Stmt.OrderTerm> order = orderBy();
        Stmt.Frame frame = null;
        boolean rows = peek().isKeyword("ROWS");
        if (rows || peek().isKeyword("RANGE")) {
            p++;
            Stmt.Bound start;
            Stmt.Bound end;
            if (acceptKeyword("BETWEEN")) {
                start = frameBound();
                expectKeyword("AND");
                end = frameBound();
            } else {
                start = frameBound();
                end = new Stmt.Bound(Stmt.BoundKind.CURRENT_ROW, null);
            }
            frame = new Stmt.Frame(rows, start, end);
        }
        expectOp(")");
        return new Stmt.WindowSpec(base, partition, order, frame);
    }

    private Stmt.Bound frameBound() {
        if (acceptKeyword("UNBOUNDED")) {
            if (acceptKeyword("PRECEDING")) return new Stmt.Bound(Stmt.BoundKind.UNBOUNDED_PRECEDING, null);
            expectKeyword("FOLLOWING");
            return new Stmt.Bound(Stmt.BoundKind.UNBOUNDED_FOLLOWING, null);
        }
        if (acceptKeyword("CURRENT")) {
            expectKeyword("ROW");
            return new Stmt.Bound(Stmt.BoundKind.CURRENT_ROW, null);
        }
        Expr e = unary();
        boolean negative = e instanceof Expr.Unary u && u.op() == '-';
        if (e instanceof Expr.Unary u) e = u.operand();
        if (!(e instanceof Expr.Literal l) || !(l.value() instanceof Long || l.value() instanceof Double)) {
            throw SqlError.syntax();
        }
        Object offset = l.value();
        if (negative) offset = offset instanceof Long k ? (Object) (-k) : (Object) (-(Double) offset);
        if (acceptKeyword("PRECEDING")) return new Stmt.Bound(Stmt.BoundKind.PRECEDING, offset);
        expectKeyword("FOLLOWING");
        return new Stmt.Bound(Stmt.BoundKind.FOLLOWING, offset);
    }

    /** After a function call's ')': OVER window-name | OVER ( window-spec ), else the call itself. */
    private Expr overClause(Expr.Call call) {
        if (!acceptKeyword("OVER")) return call;
        if (peek().kind() == Token.Kind.IDENT) {
            return new Expr.WindowCall(call, new Stmt.WindowSpec(next().text(), List.of(), List.of(), null));
        }
        return new Expr.WindowCall(call, windowSpec());
    }

    private Expr nameOrCall(String name) {
        if (acceptOp("(")) {
            List<Expr> args = new ArrayList<>();
            if (acceptOp("*")) {
                expectOp(")");
                return overClause(new Expr.Call(name, args, true, false, List.of()));
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
            return overClause(new Expr.Call(name, args, false, distinct, order));
        }
        if (acceptOp(".")) return new Expr.Name(name, expectIdent());
        return new Expr.Name(null, name);
    }
}
