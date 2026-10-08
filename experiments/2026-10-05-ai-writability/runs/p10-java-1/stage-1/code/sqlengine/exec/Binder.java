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
        return bindCall((Call) e, scope);
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
            default: return row -> Values.fromBoolean(not(Values.truth(x.eval(row))));
        }
    }

    private static Boolean not(Boolean b) {
        return b == null ? null : !b;
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
                return row -> {
                    Boolean x = Values.truth(l.eval(row));
                    Boolean y = Values.truth(r.eval(row));
                    if (Boolean.FALSE.equals(x) || Boolean.FALSE.equals(y)) return 0L;
                    return Values.fromBoolean(x == null || y == null ? null : Boolean.TRUE);
                };
            case "OR":
                return row -> {
                    Boolean x = Values.truth(l.eval(row));
                    Boolean y = Values.truth(r.eval(row));
                    if (Boolean.TRUE.equals(x) || Boolean.TRUE.equals(y)) return 1L;
                    return Values.fromBoolean(x == null || y == null ? null : Boolean.FALSE);
                };
            default:
                return comparison(op, l, r);
        }
    }

    private static Node comparison(String op, Node l, Node r) {
        SqlType la = l.affinity();
        SqlType ra = r.affinity();
        return row -> {
            Object x = l.eval(row);
            Object y = r.eval(row);
            if (x == null || y == null) return null;
            int c = Values.compareWithAffinity(x, la, y, ra);
            boolean res = switch (op) {
                case "=" -> c == 0;
                case "!=" -> c != 0;
                case "<" -> c < 0;
                case "<=" -> c <= 0;
                case ">" -> c > 0;
                default -> c >= 0;
            };
            return res ? 1L : 0L;
        };
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
}
