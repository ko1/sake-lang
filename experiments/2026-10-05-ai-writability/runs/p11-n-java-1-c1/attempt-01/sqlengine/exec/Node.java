package sqlengine.exec;

import sqlengine.value.Collation;
import sqlengine.value.SqlType;

/** A bound (name-resolved) expression, evaluated against one row of the table. */
public interface Node {
    Object eval(Object[] row);

    /** Affinity for comparisons (1.9): the column type for a column reference, else none. */
    default SqlType affinity() {
        return null;
    }

    /** The collation written as COLLATE on this expression (7.3), or null. */
    default Collation explicitCollation() {
        return null;
    }

    /** The collation this expression takes from a column it is (7.3), or null. */
    default Collation implicitCollation() {
        return null;
    }

    /** The explicit collation of n, else its implicit one, else null (none). */
    static Collation collationOf(Node n) {
        Collation c = n.explicitCollation();
        return c != null ? c : n.implicitCollation();
    }

    /** As collationOf, where no collation means BINARY (ordering, grouping, aggregates). */
    static Collation collationOrBinary(Node n) {
        Collation c = collationOf(n);
        return c != null ? c : Collation.BINARY;
    }

    /** The collation of comparing l with r (7.4). */
    static Collation forComparison(Node l, Node r) {
        return Collation.choose(l.explicitCollation(), r.explicitCollation(), l.implicitCollation(),
            r.implicitCollation());
    }
}
