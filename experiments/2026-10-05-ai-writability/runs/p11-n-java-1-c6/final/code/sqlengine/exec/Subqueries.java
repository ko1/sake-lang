package sqlengine.exec;

import java.util.List;
import sqlengine.parse.SqlError;
import sqlengine.value.SqlType;

/** Bound subquery expressions (4.3). Each run publishes the enclosing row in the frame for outer references. */
final class Subqueries {
    private Subqueries() { }

    /** A subquery with exactly one result column, else the "sub-select" error. */
    static Query single(Query q) {
        if (q.outputs().size() != 1) {
            throw new SqlError("sub-select returns " + q.outputs().size() + " columns - expected 1");
        }
        return q;
    }

    private static List<Object[]> runIn(Query q, Frame frame, Object[] row) {
        Object[] saved = frame.row;
        frame.row = row;
        try {
            return q.run();
        } finally {
            frame.row = saved;
        }
    }

    /** ( select ): the first column of the first row, or NULL; it has its result column's affinity. */
    static Node scalar(Query q, Frame frame) {
        SqlType affinity = q.outputs().get(0).type();
        return new Node() {
            @Override
            public Object eval(Object[] row) {
                List<Object[]> rows = runIn(q, frame, row);
                return rows.isEmpty() ? null : rows.get(0)[0];
            }

            @Override
            public SqlType affinity() {
                return affinity;
            }
        };
    }

    static Node exists(Query q, Frame frame, boolean negated) {
        return row -> runIn(q, frame, row).isEmpty() == negated ? 1L : 0L;
    }

    /** x [NOT] IN ( select ); the single column must already be checked. */
    static Node in(Node x, Query q, Frame frame, boolean negated) {
        SqlType xa = x.affinity();
        SqlType itemAffinity = q.outputs().get(0).type();
        return row -> {
            Object v = x.eval(row);
            List<Object[]> rows = runIn(q, frame, row);
            Object[] items = new Object[rows.size()];
            for (int i = 0; i < items.length; i++) items[i] = rows.get(i)[0];
            Object res = rows.isEmpty() ? (Object) 0L : Operators.in(v, xa, items, itemAffinity);
            return negated ? Operators.not(res) : res;
        };
    }

    /** A reference to the enclosing query's row: reads node (bound in that query) on the frame's row. */
    static Node outer(Node node, Frame frame) {
        return new Node() {
            @Override
            public Object eval(Object[] row) {
                return node.eval(frame.row);
            }

            @Override
            public SqlType affinity() {
                return node.affinity();
            }
        };
    }
}
