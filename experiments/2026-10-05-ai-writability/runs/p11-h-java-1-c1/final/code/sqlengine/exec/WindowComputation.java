package sqlengine.exec;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import sqlengine.parse.Ast.Call;
import sqlengine.parse.Ast.Expr;
import sqlengine.parse.Ast.OrderTerm;
import sqlengine.parse.Ast.WindowSpec;
import sqlengine.value.Collation;

/** One bound window call (6.2): partitions the rows, orders each partition, and fills a slot of every row. */
final class WindowComputation {
    private final List<Node> partitionBy;
    private final List<Node> orderBy;
    private final List<Ordering.Key> keys;
    private final WindowFrame frame;
    private final WindowFunction function;
    private final Collation[] partitionCollations;

    private WindowComputation(List<Node> partitionBy, List<Node> orderBy, List<Ordering.Key> keys, WindowFrame frame,
                              WindowFunction function) {
        this.partitionBy = partitionBy;
        this.orderBy = orderBy;
        this.keys = keys;
        this.frame = frame;
        this.function = function;
        this.partitionCollations = partitionBy.stream().map(Node::collation).toArray(Collation[]::new);
    }

    /** Binds call with the already resolved spec; scope must reject window calls (they do not nest). */
    static WindowComputation bind(Call call, WindowSpec spec, Scope scope) {
        WindowFunction fn = WindowFunctions.bind(call, scope);
        List<Node> partitionBy = new ArrayList<>();
        for (Expr e : spec.partitionBy()) partitionBy.add(Binder.bind(e, scope)); // a literal is a constant here
        List<Node> orderBy = new ArrayList<>();
        List<Ordering.Key> keys = new ArrayList<>();
        for (OrderTerm t : spec.orderBy()) {
            Node node = Binder.bind(t.expr(), scope);
            orderBy.add(node);
            keys.add(Ordering.Key.of(t, node.collation()));
        }
        return new WindowComputation(partitionBy, orderBy, keys, WindowFrame.of(spec.frame(), spec.orderBy()), fn);
    }

    /** Sets row[slot] of every row to this call's result for it. */
    void run(List<Object[]> rows, int slot) {
        Map<List<Object>, List<Integer>> partitions = new LinkedHashMap<>();
        Object[][] orderValues = new Object[rows.size()][];
        for (int i = 0; i < rows.size(); i++) {
            Object[] row = rows.get(i);
            Object[] key = new Object[partitionBy.size()];
            for (int k = 0; k < key.length; k++) key[k] = partitionBy.get(k).eval(row);
            partitions.computeIfAbsent(RowSets.key(key, partitionCollations), x -> new ArrayList<>()).add(i);
            orderValues[i] = new Object[orderBy.size()];
            for (int k = 0; k < orderBy.size(); k++) orderValues[i][k] = orderBy.get(k).eval(row);
        }
        for (List<Integer> members : partitions.values()) {
            members.sort((a, b) -> Ordering.compare(keys, orderValues[a], orderValues[b])); // stable
            List<Object[]> sorted = new ArrayList<>(members.size());
            Object[][] values = new Object[members.size()][];
            for (int i = 0; i < values.length; i++) {
                sorted.add(rows.get(members.get(i)));
                values[i] = orderValues[members.get(i)];
            }
            Partition p = new Partition(sorted, values, keys);
            Object[] out = new Object[p.size()];
            function.compute(p, frame, out);
            for (int i = 0; i < out.length; i++) sorted.get(i)[slot] = out[i];
        }
    }
}
