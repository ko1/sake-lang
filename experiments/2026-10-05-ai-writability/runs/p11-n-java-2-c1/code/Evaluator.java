import java.util.List;

/** Evaluates a resolved expression against the current row and the rows of the enclosing queries (Env). */
final class Evaluator {
    private Evaluator() {}

    static Object eval(Expr e, Env env) {
        return switch (e) {
            case Expr.Literal l -> l.value();
            case Expr.ColumnRef c -> env.get(c.depth(), c.index());
            case Expr.AggRef a -> env.row()[a.index()];
            case Expr.WinRef w -> env.row()[env.row().length - 1 - w.slot()];
            case Expr.WindowCall w -> throw new IllegalStateException("unresolved window call");
            case Expr.Name n -> throw new IllegalStateException("unresolved name " + n.text());
            case Expr.Unary u -> unary(u.op(), eval(u.operand(), env));
            case Expr.Not n -> Values.fromTruth(negate(Values.truth(eval(n.operand(), env))));
            case Expr.Call c -> call(c, env);
            case Expr.Binary b -> binary(b, env);
            case Expr.Case c -> caseExpr(c, env);
            case Expr.Between b -> between(b, env);
            case Expr.In i -> in(i, env);
            case Expr.Like l -> like(l, env);
            case Expr.ScalarSub s -> {
                List<Object[]> rows = s.plan().execute(env);
                yield rows.isEmpty() ? null : rows.get(0)[0];
            }
            case Expr.ExistsSub s -> s.plan().execute(env).isEmpty() ? 0L : 1L;
            case Expr.InSub i -> inSubquery(i, env);
            case Expr.Subquery s -> throw new IllegalStateException("unresolved subquery");
            case Expr.Exists s -> throw new IllegalStateException("unresolved subquery");
            case Expr.InSelect s -> throw new IllegalStateException("unresolved subquery");
            case Expr.Collate c -> eval(c.operand(), env);
            case Expr.Cast c -> {
                Object v = eval(c.operand(), env);
                yield v == null ? null : Values.cast(v, c.type());
            }
        };
    }

    private static Object caseExpr(Expr.Case c, Env env) {
        Object base = c.base() == null ? null : eval(c.base(), env);
        for (Expr.When w : c.whens()) {
            Object v = eval(w.condition(), env);
            boolean hit;
            if (c.base() == null) {
                hit = Values.truth(v) == Boolean.TRUE;
            } else {
                hit = base != null && v != null && Values.compareWithAffinity(
                    base, Values.affinity(c.base()), v, Values.affinity(w.condition()),
                    Collation.forComparison(c.base(), w.condition())) == 0;
            }
            if (hit) return eval(w.result(), env);
        }
        return c.otherwise() == null ? null : eval(c.otherwise(), env);
    }

    private static Object between(Expr.Between b, Env env) {
        Object x = eval(b.operand(), env);
        Object lo = eval(b.low(), env);
        Object hi = eval(b.high(), env);
        Boolean ge = x == null || lo == null ? null
            : Values.compareWithAffinity(x, Values.affinity(b.operand()), lo, Values.affinity(b.low()),
                Collation.forComparison(b.operand(), b.low())) >= 0;
        Boolean le = x == null || hi == null ? null
            : Values.compareWithAffinity(x, Values.affinity(b.operand()), hi, Values.affinity(b.high()),
                Collation.forComparison(b.operand(), b.high())) <= 0;
        Boolean r = and(ge, le);
        return Values.fromTruth(b.negated() ? negate(r) : r);
    }

    /** Only the operand's affinity and collation count: each item is converted to the affinity, then compared. */
    private static Object in(Expr.In in, Env env) {
        Object x = eval(in.operand(), env);
        Boolean r;
        if (x == null) {
            r = null;
        } else {
            ColType aff = Values.affinity(in.operand());
            Collation coll = Collation.of(in.operand());
            r = false;
            for (Expr item : in.items()) {
                Object v = eval(item, env);
                if (v == null) {
                    r = null;
                } else if (Values.compare(x, Values.applyAffinity(v, aff), coll) == 0) {
                    r = true;
                    break;
                }
            }
        }
        return Values.fromTruth(in.negated() ? negate(r) : r);
    }

    /** x IN (select): each value compared as x = v, v having the affinity and collation of the subquery's column. */
    private static Object inSubquery(Expr.InSub in, Env env) {
        Object x = eval(in.operand(), env);
        List<Object[]> rows = in.plan().execute(env);
        Boolean r;
        if (rows.isEmpty()) {
            r = false;
        } else if (x == null) {
            r = null;
        } else {
            ColType aff = Values.affinity(in.operand());
            Collation coll = Collation.choose(Collation.explicit(in.operand()), Collation.implicit(in.operand()),
                in.plan().explicitCollation(0), in.plan().implicitCollation(0));
            r = false;
            for (Object[] row : rows) {
                Object v = row[0];
                if (v == null) {
                    r = null;
                } else if (Values.compareWithAffinity(x, aff, v, in.plan().type(0), coll) == 0) {
                    r = true;
                    break;
                }
            }
        }
        return Values.fromTruth(in.negated() ? negate(r) : r);
    }

    private static Object like(Expr.Like l, Env env) {
        Object x = eval(l.operand(), env);
        Object p = eval(l.pattern(), env);
        if (x == null || p == null) return null;
        boolean m = LikeMatcher.matches(Values.textForm(x), Values.textForm(p));
        return m != l.negated() ? 1L : 0L;
    }

    private static Boolean negate(Boolean b) {
        return b == null ? null : !b;
    }

    private static Object call(Expr.Call c, Env env) {
        Object[] args = new Object[c.args().size()];
        for (int i = 0; i < args.length; i++) args[i] = eval(c.args().get(i), env);
        return Functions.call(c.name(), args);
    }

    private static Object unary(char op, Object v) {
        if (op == '+' || v == null) return v;
        Object n = Values.toNumber(v);
        return n instanceof Long l ? (Object) (-l) : (Object) (-(Double) n);
    }

    private static Object binary(Expr.Binary b, Env env) {
        Object l = eval(b.left(), env);
        Object r = eval(b.right(), env);
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
        return Values.compareWithAffinity(l, Values.affinity(b.left()), r, Values.affinity(b.right()),
            Collation.forComparison(b.left(), b.right()));
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
