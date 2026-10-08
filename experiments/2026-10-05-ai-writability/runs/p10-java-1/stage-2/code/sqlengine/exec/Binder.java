package sqlengine.exec;

import java.util.List;
import sqlengine.parse.Ast.*;
import sqlengine.parse.SqlError;
import sqlengine.value.Names;
import sqlengine.value.SqlType;
import sqlengine.value.Values;

/** Resolves names and functions in an expression tree, producing an evaluable Node tree. */
final class Binder {
    private Binder() { }

    /** A reference to column idx of the current row. */
    record ColumnNode(int idx, SqlType type) implements Node {
        @Override
        public Object eval(Object[] row) {
            return row[idx];
        }

        @Override
        public SqlType affinity() {
            return type;
        }
    }

    static Node bind(Expr e, Scope scope) {
        if (e instanceof Literal l) {
            Object v = l.value();
            return row -> v;
        }
        if (e instanceof Name n) return bindName(n.name(), scope);
        if (e instanceof Unary u) return bindUnary(u, scope);
        if (e instanceof Binary b) return bindBinary(b, scope);
        if (e instanceof Is is) return bindIs(is, scope);
        if (e instanceof Call c) return bindCall(c, scope);
        if (e instanceof Case c) return bindCase(c, scope);
        if (e instanceof Between b) return bindBetween(b, scope);
        if (e instanceof In in) return bindIn(in, scope);
        if (e instanceof Like l) return bindLike(l, scope);
        return bindCast((Cast) e, scope);
    }

    private static Node bindName(String name, Scope scope) {
        List<Column> cols = scope.columns();
        for (int i = 0; i < cols.size(); i++) {
            if (Names.same(cols.get(i).name(), name)) return new ColumnNode(i, cols.get(i).type());
        }
        if (scope.aliases() != null) {
            Node a = scope.aliases().get(Names.norm(name));
            if (a != null) return a;
        }
        throw new SqlError("no such column: " + name);
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
        Node l = bind(b.left(), scope);
        Node r = bind(b.right(), scope);
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
                return row -> Operators.compare(op, l.eval(row), la, r.eval(row), ra);
            }
        }
    }

    private static Node bindIs(Is is, Scope scope) {
        Node l = bind(is.left(), scope);
        Node r = bind(is.right(), scope);
        SqlType la = l.affinity();
        SqlType ra = r.affinity();
        boolean neg = is.negated();
        return row -> {
            Object x = l.eval(row);
            Object y = r.eval(row);
            boolean same;
            if (x == null || y == null) same = x == null && y == null;
            else same = Values.compareWithAffinity(x, la, y, ra) == 0;
            return same != neg ? 1L : 0L;
        };
    }

    private static Node bindCall(Call c, Scope scope) {
        Node[] args = c.args().stream().map(a -> bind(a, scope)).toArray(Node[]::new);
        Functions.Fn fn = Functions.lookup(c.name(), args.length);
        return row -> {
            Object[] vals = new Object[args.length];
            for (int i = 0; i < args.length; i++) vals[i] = args[i].eval(row);
            return fn.apply(vals);
        };
    }

    private static Node bindCase(Case c, Scope scope) {
        Node operand = c.operand() == null ? null : bind(c.operand(), scope);
        int n = c.whens().size();
        Node[] conds = new Node[n];
        Node[] results = new Node[n];
        for (int i = 0; i < n; i++) {
            conds[i] = bind(c.whens().get(i).condition(), scope);
            results[i] = bind(c.whens().get(i).result(), scope);
        }
        Node otherwise = c.elseResult() == null ? row -> null : bind(c.elseResult(), scope);
        SqlType oa = operand == null ? null : operand.affinity();
        return row -> {
            Object x = operand == null ? null : operand.eval(row);
            for (int i = 0; i < n; i++) {
                Object cv = conds[i].eval(row);
                boolean hit = operand == null
                    ? Boolean.TRUE.equals(Values.truth(cv))
                    : Operators.compare("=", x, oa, cv, conds[i].affinity()) instanceof Long l && l == 1;
                if (hit) return results[i].eval(row);
            }
            return otherwise.eval(row);
        };
    }

    private static Node bindBetween(Between b, Scope scope) {
        Node x = bind(b.value(), scope);
        Node lo = bind(b.low(), scope);
        Node hi = bind(b.high(), scope);
        boolean neg = b.negated();
        return row -> {
            Object v = x.eval(row);
            Object res = Operators.and(
                Operators.compare(">=", v, x.affinity(), lo.eval(row), lo.affinity()),
                Operators.compare("<=", v, x.affinity(), hi.eval(row), hi.affinity()));
            return neg ? Operators.not(res) : res;
        };
    }

    private static Node bindIn(In in, Scope scope) {
        Node x = bind(in.value(), scope);
        Node[] items = in.items().stream().map(i -> bind(i, scope)).toArray(Node[]::new);
        boolean neg = in.negated();
        return row -> {
            Object[] vals = new Object[items.length];
            for (int i = 0; i < vals.length; i++) vals[i] = items[i].eval(row);
            Object res = Operators.in(x.eval(row), x.affinity(), vals);
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
    }

    private static Node bindCast(Cast c, Scope scope) {
        return new CastNode(bind(c.value(), scope), c.type());
    }
}
