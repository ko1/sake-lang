package sqlengine.exec;

import java.util.List;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Collation;
import sqlengine.value.Names;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/** Resolves names and functions in an expression tree, producing an evaluable Node tree. */
final class Binder {
    private Binder() { }

    /** A reference to column idx of the current row; its collation is implicit (7.3). */
    record ColumnNode(int idx, SqlType type, Collation collation) implements Node {
        @Override
        public Object eval(Object[] row) {
            return row[idx];
        }

        @Override
        public SqlType affinity() {
            return type;
        }
    }

    /** e COLLATE n: e's value and affinity, with explicit collation n (7.3). */
    private record CollateNode(Node operand, Collation collation) implements Node {
        @Override
        public Object eval(Object[] row) {
            return operand.eval(row);
        }

        @Override
        public SqlType affinity() {
            return operand.affinity();
        }

        @Override
        public boolean explicitCollation() {
            return true;
        }
    }

    static Node bind(Expr e, Scope scope) {
        if (e instanceof Literal l) {
            Object v = l.value();
            return row -> v;
        }
        if (e instanceof Name n) return bindName(n, scope);
        if (e instanceof Subquery sq) return Subqueries.scalar(subquery(sq.select(), scope, true), scope.frame());
        if (e instanceof Exists ex) {
            return Subqueries.exists(QueryCompiler.compile(ex.select(), scope), scope.frame(),
                ex.negated());
        }
        if (e instanceof InSelect in) return bindInSelect(in, scope);
        if (e instanceof Unary u) return bindUnary(u, scope);
        if (e instanceof Binary b) return bindBinary(b, scope);
        if (e instanceof Is is) return bindIs(is, scope);
        if (e instanceof Call c) return bindCall(c, scope);
        if (e instanceof WindowCall w) return scope.windows().call(w, scope);
        if (e instanceof Case c) return bindCase(c, scope);
        if (e instanceof Between b) return bindBetween(b, scope);
        if (e instanceof In in) return bindIn(in, scope);
        if (e instanceof Like l) return bindLike(l, scope);
        if (e instanceof Collate c) return new CollateNode(bind(c.value(), scope), Column.collationNamed(c.name()));
        return bindCast((Cast) e, scope);
    }

    /** Compiles a subquery of the query bound in scope; single requires exactly one result column. */
    private static Query subquery(Select select, Scope scope, boolean single) {
        Query q = QueryCompiler.compile(select, scope);
        return single ? Subqueries.single(q) : q;
    }

    private static Node bindInSelect(InSelect in, Scope scope) {
        Node x = bind(in.value(), scope);
        return Subqueries.in(x, subquery(in.select(), scope, true), scope.frame(), in.negated());
    }

    /**
     * An operand of a comparison, BETWEEN or CASE x: a scalar subquery here with several columns is
     * "row value misused" rather than the "sub-select" error (4.3).
     */
    private static Node bindOperand(Expr e, Scope scope) {
        if (e instanceof Subquery sq) {
            Query q = subquery(sq.select(), scope, false);
            if (q.outputs().size() != 1) throw new SqlError("row value misused");
            return Subqueries.scalar(q, scope.frame());
        }
        return bind(e, scope);
    }

    private static Node bindName(Name n, Scope scope) {
        Node r = resolve(n, scope);
        if (r == null) {
            throw new SqlError("no such column: " + (n.qualifier() == null ? "" : n.qualifier() + ".") + n.name());
        }
        return r;
    }

    /** The node for a column name (4.2), or null if no scope in the chain knows it. */
    private static Node resolve(Name n, Scope scope) {
        Layout layout = scope.layout();
        if (n.qualifier() == null || layout.source(n.qualifier()) != null) {
            int idx = layout.find(n.qualifier(), n.name());
            if (idx >= 0) return new ColumnNode(idx, layout.column(idx).type(), layout.column(idx).collation());
            if (n.qualifier() != null) return null; // the innermost query with that source decides
            if (scope.aliases() != null) {
                Expr a = scope.aliases().get(Names.norm(n.name()));
                if (a != null) {
                    if (Exprs.containsWindow(a)) scope.windows().aliasUse(n.name());
                    Call agg = Aggregates.firstAggregate(a);
                    if (agg != null) scope.agg().aliasUse(agg.name());
                    return bind(a, scope.withAliases(null)); // an alias stands for its expression
                }
            }
        }
        if (scope.outer() == null) return null;
        Node o = resolve(n, scope.outer());
        return o == null ? null : Subqueries.outer(o, scope.outer().frame());
    }

    private static Node bindUnary(Unary u, Scope scope) {
        Node x = bind(u.operand(), scope);
        switch (u.op()) {
            case "-": return row -> Operators.negate(x.eval(row));
            case "+": return x;
            default: return row -> Operators.not(x.eval(row));
        }
    }

    private static Node bindBinary(Binary b, Scope scope) {
        boolean comparison = !List.of("+", "-", "*", "/", "%", "||", "AND", "OR").contains(b.op());
        Node l = comparison ? bindOperand(b.left(), scope) : bind(b.left(), scope);
        Node r = comparison ? bindOperand(b.right(), scope) : bind(b.right(), scope);
        String op = b.op();
        switch (op) {
            case "+", "-", "*", "/", "%":
                return row -> Operators.arith(op, l.eval(row), r.eval(row));
            case "||":
                return row -> Operators.concat(l.eval(row), r.eval(row));
            case "AND":
                return row -> Operators.and(l.eval(row), r.eval(row));
            case "OR":
                return row -> Operators.or(l.eval(row), r.eval(row));
            default: {
                SqlType la = l.affinity();
                SqlType ra = r.affinity();
                Collation coll = Operators.choose(l, r);
                return row -> Operators.compare(op, l.eval(row), la, r.eval(row), ra, coll);
            }
        }
    }

    private static Node bindIs(Is is, Scope scope) {
        boolean nullTest = is.right() instanceof Literal lit && lit.value() == null;
        Node l = nullTest ? bind(is.left(), scope) : bindOperand(is.left(), scope);
        Node r = nullTest ? bind(is.right(), scope) : bindOperand(is.right(), scope);
        SqlType la = l.affinity();
        SqlType ra = r.affinity();
        boolean neg = is.negated();
        Collation coll = Operators.choose(l, r);
        return row -> {
            Object x = l.eval(row);
            Object y = r.eval(row);
            boolean same;
            if (x == null || y == null) same = x == null && y == null;
            else same = Values.compareWithAffinity(x, la, y, ra, coll) == 0;
            return same != neg ? 1L : 0L;
        };
    }

    private static Node bindCall(Call c, Scope scope) {
        if (Aggregates.isAggregate(c)) return scope.agg().call(c, scope);
        if (Windows.isWindowOnly(c.name())) throw Windows.misuse(c.name());
        if (c.star()) throw new SqlError("wrong number of arguments to function " + c.name() + "()");
        if (c.distinct() || !c.orderBy().isEmpty()) throw SqlError.syntax();
        Node[] args = c.args().stream().map(a -> bind(a, scope)).toArray(Node[]::new);
        Functions.Fn fn = Functions.lookup(c.name(), args.length);
        return row -> {
            Object[] vals = new Object[args.length];
            for (int i = 0; i < args.length; i++) vals[i] = args[i].eval(row);
            return fn.apply(vals);
        };
    }

    private static Node bindCase(Case c, Scope scope) {
        Node operand = c.operand() == null ? null : bindOperand(c.operand(), scope);
        int n = c.whens().size();
        Node[] conds = new Node[n];
        Node[] results = new Node[n];
        for (int i = 0; i < n; i++) {
            conds[i] = bind(c.whens().get(i).condition(), scope);
            results[i] = bind(c.whens().get(i).result(), scope);
        }
        Node otherwise = c.elseResult() == null ? row -> null : bind(c.elseResult(), scope);
        SqlType oa = operand == null ? null : operand.affinity();
        Collation[] colls = new Collation[n]; // each WHEN v compares as operand = v
        for (int i = 0; i < n && operand != null; i++) colls[i] = Operators.choose(operand, conds[i]);
        return row -> {
            Object x = operand == null ? null : operand.eval(row);
            for (int i = 0; i < n; i++) {
                Object cv = conds[i].eval(row);
                boolean hit = operand == null
                    ? Boolean.TRUE.equals(Values.truth(cv))
                    : Operators.compare("=", x, oa, cv, conds[i].affinity(), colls[i]) instanceof Long l && l == 1;
                if (hit) return results[i].eval(row);
            }
            return otherwise.eval(row);
        };
    }

    private static Node bindBetween(Between b, Scope scope) {
        Node x = bindOperand(b.value(), scope);
        Node lo = bindOperand(b.low(), scope);
        Node hi = bindOperand(b.high(), scope);
        boolean neg = b.negated();
        Collation loColl = Operators.choose(x, lo); // x >= lo and x <= hi each choose separately
        Collation hiColl = Operators.choose(x, hi);
        return row -> {
            Object v = x.eval(row);
            Object res = Operators.and(
                Operators.compare(">=", v, x.affinity(), lo.eval(row), lo.affinity(), loColl),
                Operators.compare("<=", v, x.affinity(), hi.eval(row), hi.affinity(), hiColl));
            return neg ? Operators.not(res) : res;
        };
    }

    private static Node bindIn(In in, Scope scope) {
        Node x = bind(in.value(), scope);
        Node[] items = in.items().stream().map(i -> bind(i, scope)).toArray(Node[]::new);
        boolean neg = in.negated();
        Collation coll = x.collation(); // only x counts (7.4)
        return row -> {
            Object[] vals = new Object[items.length];
            for (int i = 0; i < vals.length; i++) vals[i] = items[i].eval(row);
            Object res = Operators.in(x.eval(row), x.affinity(), vals, coll);
            return neg ? Operators.not(res) : res;
        };
    }

    private static Node bindLike(Like l, Scope scope) {
        Node x = bind(l.value(), scope);
        Node p = bind(l.pattern(), scope);
        boolean neg = l.negated();
        return row -> {
            Object res = Operators.like(x.eval(row), p.eval(row));
            return neg ? Operators.not(res) : res;
        };
    }

    /** CAST has the affinity of its target type (1.9). */
    private record CastNode(Node operand, SqlType type) implements Node {
        @Override
        public Object eval(Object[] row) {
            return Operators.cast(operand.eval(row), type);
        }

        @Override
        public SqlType affinity() {
            return type;
        }

        @Override
        public Collation collation() {
            return operand.collation();
        }

        @Override
        public boolean explicitCollation() {
            return operand.explicitCollation();
        }
    }

    private static Node bindCast(Cast c, Scope scope) {
        return new CastNode(bind(c.value(), scope), c.type());
    }
}
