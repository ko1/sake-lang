/** Evaluates a resolved expression against one row (an Object[] of column values). */
final class Evaluator {
    private Evaluator() {}

    static Object eval(Expr e, Object[] row) {
        return switch (e) {
            case Expr.Literal l -> l.value();
            case Expr.ColumnRef c -> row[c.index()];
            case Expr.AggRef a -> row[a.index()];
            case Expr.Name n -> throw new IllegalStateException("unresolved name " + n.text());
            case Expr.Unary u -> unary(u.op(), eval(u.operand(), row));
            case Expr.Not n -> Values.fromTruth(negate(Values.truth(eval(n.operand(), row))));
            case Expr.Call c -> call(c, row);
            case Expr.Binary b -> binary(b, row);
            case Expr.Case c -> caseExpr(c, row);
            case Expr.Between b -> between(b, row);
            case Expr.In i -> in(i, row);
            case Expr.Like l -> like(l, row);
            case Expr.Cast c -> {
                Object v = eval(c.operand(), row);
                yield v == null ? null : Values.cast(v, c.type());
            }
        };
    }

    private static Object caseExpr(Expr.Case c, Object[] row) {
        Object base = c.base() == null ? null : eval(c.base(), row);
        for (Expr.When w : c.whens()) {
            Object v = eval(w.condition(), row);
            boolean hit;
            if (c.base() == null) {
                hit = Values.truth(v) == Boolean.TRUE;
            } else {
                hit = base != null && v != null && Values.compareWithAffinity(
                    base, Values.affinity(c.base()), v, Values.affinity(w.condition())) == 0;
            }
            if (hit) return eval(w.result(), row);
        }
        return c.otherwise() == null ? null : eval(c.otherwise(), row);
    }

    private static Object between(Expr.Between b, Object[] row) {
        Object x = eval(b.operand(), row);
        Object lo = eval(b.low(), row);
        Object hi = eval(b.high(), row);
        Boolean ge = x == null || lo == null ? null
            : Values.compareWithAffinity(x, Values.affinity(b.operand()), lo, Values.affinity(b.low())) >= 0;
        Boolean le = x == null || hi == null ? null
            : Values.compareWithAffinity(x, Values.affinity(b.operand()), hi, Values.affinity(b.high())) <= 0;
        Boolean r = and(ge, le);
        return Values.fromTruth(b.negated() ? negate(r) : r);
    }

    /** Only the operand's affinity counts: each item is converted to it, then compared by value. */
    private static Object in(Expr.In in, Object[] row) {
        Object x = eval(in.operand(), row);
        Boolean r;
        if (x == null) {
            r = null;
        } else {
            ColType aff = Values.affinity(in.operand());
            r = false;
            for (Expr item : in.items()) {
                Object v = eval(item, row);
                if (v == null) {
                    r = null;
                } else if (Values.compare(x, Values.applyAffinity(v, aff)) == 0) {
                    r = true;
                    break;
                }
            }
        }
        return Values.fromTruth(in.negated() ? negate(r) : r);
    }

    private static Object like(Expr.Like l, Object[] row) {
        Object x = eval(l.operand(), row);
        Object p = eval(l.pattern(), row);
        if (x == null || p == null) return null;
        boolean m = LikeMatcher.matches(Values.textForm(x), Values.textForm(p));
        return m != l.negated() ? 1L : 0L;
    }

    private static Boolean negate(Boolean b) {
        return b == null ? null : !b;
    }

    private static Object call(Expr.Call c, Object[] row) {
        Object[] args = new Object[c.args().size()];
        for (int i = 0; i < args.length; i++) args[i] = eval(c.args().get(i), row);
        return Functions.call(c.name(), args);
    }

    private static Object unary(char op, Object v) {
        if (op == '+' || v == null) return v;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? (Object) (-l) : (Object) (-(Double) n);
    }

    private static Object binary(Expr.Binary b, Object[] row) {
        Object l = eval(b.left(), row);
        Object r = eval(b.right(), row);
        switch (b.op()) {
            case AND: return Values.fromTruth(and(Values.truth(l), Values.truth(r)));
            case OR: return Values.fromTruth(or(Values.truth(l), Values.truth(r)));
            case CONCAT:
                return l == null || r == null ? null : Values.textForm(l) + Values.textForm(r);
            case ADD: case SUB: case MUL: case DIV: case MOD:
                return arithmetic(b.op(), l, r);
            case IS: case ISNOT: {
                boolean same;
                if (l == null || r == null) same = l == r;
                else same = compare(b, l, r) == 0;
                return same == (b.op() == Expr.BinOp.IS) ? 1L : 0L;
            }
            default: {
                if (l == null || r == null) return null;
                int c = compare(b, l, r);
                boolean res = switch (b.op()) {
                    case EQ -> c == 0;
                    case NE -> c != 0;
                    case LT -> c < 0;
                    case LE -> c <= 0;
                    case GT -> c > 0;
                    default -> c >= 0;
                };
                return res ? 1L : 0L;
            }
        }
    }

    private static int compare(Expr.Binary b, Object l, Object r) {
        return Values.compareWithAffinity(l, Values.affinity(b.left()), r, Values.affinity(b.right()));
    }

    private static Boolean and(Boolean a, Boolean b) {
        if (a == Boolean.FALSE || b == Boolean.FALSE) return false;
        return a == null || b == null ? null : true;
    }

    private static Boolean or(Boolean a, Boolean b) {
        if (a == Boolean.TRUE || b == Boolean.TRUE) return true;
        return a == null || b == null ? null : false;
    }

    private static Object arithmetic(Expr.BinOp op, Object l, Object r) {
        if (l == null || r == null) return null;
        Object x = Values.toNumber(l);
        Object y = Values.toNumber(r);
        if (x instanceof Long a && y instanceof Long b) {
            return switch (op) {
                case ADD -> (Object) (a + b);
                case SUB -> (Object) (a - b);
                case MUL -> (Object) (a * b);
                case DIV -> b == 0 ? null : (Object) (a / b);
                default -> b == 0 ? null : (Object) (a % b);
            };
        }
        double a = Values.toDouble(x);
        double b = Values.toDouble(y);
        return switch (op) {
            case ADD -> (Object) (a + b);
            case SUB -> (Object) (a - b);
            case MUL -> (Object) (a * b);
            case DIV -> b == 0 ? null : (Object) (a / b);
            default -> {
                long bi = (long) b;
                yield bi == 0 ? null : (Object) (double) ((long) a % bi);
            }
        };
    }
}
