package sqlengine.exec;

import java.util.List;
import java.util.Map;

/**
 * What names mean while binding: the table's columns, plus (where allowed) result-column
 * aliases keyed by normalised name.
 */
public record Scope(List<Column> columns, Map<String, Node> aliases) {
    public Scope withAliases(Map<String, Node> a) {
        return new Scope(columns, a);
    }
}
