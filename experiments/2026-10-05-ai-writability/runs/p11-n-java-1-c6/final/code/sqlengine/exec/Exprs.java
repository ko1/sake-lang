package sqlengine.exec;

import java.util.ArrayList;
import java.util.List;
import sqlengine.parse.Ast.*;

/** Generic walks over expression trees. */
final class Exprs {
    private Exprs() { }

    /** The direct sub-expressions of e, in evaluation order; a subquery's own contents are not included. */
    static List<Expr> children(Expr e) {
        List<Expr> out = new ArrayList<>();
        if (e instanceof Unary u) {
            out.add(u.operand());
        } else if (e instanceof Binary b) {
            out.add(b.left());
            out.add(b.right());
        } else if (e instanceof Is i) {
            out.add(i.left());
            out.add(i.right());
        } else if (e instanceof Call c) {
            addCall(c, out);
        } else if (e instanceof WindowCall w) {
            addCall(w.call(), out);
            out.addAll(w.spec().partitionBy());
            for (OrderTerm t : w.spec().orderBy()) out.add(t.expr());
        } else if (e instanceof Between b) {
            out.add(b.value());
            out.add(b.low());
            out.add(b.high());
        } else if (e instanceof Like l) {
            out.add(l.value());
            out.add(l.pattern());
        } else if (e instanceof Cast c) {
            out.add(c.value());
        } else if (e instanceof InSelect in) {
            out.add(in.value());
        } else if (e instanceof In in) {
            out.add(in.value());
            out.addAll(in.items());
        } else if (e instanceof Case c) {
            if (c.operand() != null) out.add(c.operand());
            for (When w : c.whens()) {
                out.add(w.condition());
                out.add(w.result());
            }
            if (c.elseResult() != null) out.add(c.elseResult());
        }
        return out;
    }

    private static void addCall(Call c, List<Expr> out) {
        out.addAll(c.args());
        for (OrderTerm t : c.orderBy()) out.add(t.expr());
    }

    /** True if a window call (6.2) is written anywhere in e (outside subqueries). */
    static boolean containsWindow(Expr e) {
        if (e instanceof WindowCall) return true;
        for (Expr child : children(e)) {
            if (containsWindow(child)) return true;
        }
        return false;
    }
}
