package sqlengine.parse;

import java.util.List;
import sqlengine.value.SqlType;

/** Syntax trees produced by Parser. Names are kept as written; resolution happens in exec. */
public final class Ast {
    private Ast() { }

    // ---- expressions ----
    public sealed interface Expr permits Literal, Name, Unary, Binary, Is, Call, Case, Between, In, Like, Cast,
        Subquery, Exists, InSelect, WindowCall, Collate { }

    /** value: null, Long, Double or String. */
    public record Literal(Object value) implements Expr { }

    /** A column reference; qualifier is the source name in q.c (4.2), else null. */
    public record Name(String qualifier, String name) implements Expr {
        public Name(String name) {
            this(null, name);
        }
    }

    /** op: "-", "+" or "NOT". */
    public record Unary(String op, Expr operand) implements Expr { }

    /** op: + - * / % || = != < <= > >= AND OR ("==" and "<>" are normalised to "=" and "!="). */
    public record Binary(String op, Expr left, Expr right) implements Expr { }

    public record Is(Expr left, Expr right, boolean negated) implements Expr { }

    /**
     * A function call. star is count(*) (args empty); distinct and orderBy (empty when absent) are the
     * aggregate-only DISTINCT and ORDER BY inside the parentheses (3.2).
     */
    public record Call(String name, List<Expr> args, boolean star, boolean distinct, List<OrderTerm> orderBy)
        implements Expr {
        public Call(String name, List<Expr> args) {
            this(name, args, false, false, List.of());
        }
    }

    public record When(Expr condition, Expr result) { }

    /** operand == null is the searched form (CASE WHEN c ...); elseResult may be null. */
    public record Case(Expr operand, List<When> whens, Expr elseResult) implements Expr { }

    public record Between(Expr value, Expr low, Expr high, boolean negated) implements Expr { }

    public record In(Expr value, List<Expr> items, boolean negated) implements Expr { }

    public record Like(Expr value, Expr pattern, boolean negated) implements Expr { }

    public record Cast(Expr value, SqlType type) implements Expr { }

    /** value COLLATE collation (7.2); collation is the name as written. */
    public record Collate(Expr value, String collation) implements Expr { }

    /** A scalar subquery (4.3). */
    public record Subquery(Select select) implements Expr { }

    public record Exists(Select select, boolean negated) implements Expr { }

    public record InSelect(Expr value, Select select, boolean negated) implements Expr { }

    // ---- window functions (6.1) ----
    /** A call followed by OVER: spec is the window-spec written, or just a base name for "OVER name". */
    public record WindowCall(Call call, WindowSpec spec) implements Expr { }

    /** base is the name of a named window it extends, or null; frame is null when not written. */
    public record WindowSpec(String base, List<Expr> partitionBy, List<OrderTerm> orderBy, FrameSpec frame) { }

    public enum FrameMode { ROWS, RANGE }

    public enum BoundKind { UNBOUNDED_PRECEDING, PRECEDING, CURRENT_ROW, FOLLOWING, UNBOUNDED_FOLLOWING }

    /** offset (a Long or Double, as written, possibly negative) is set for PRECEDING and FOLLOWING only. */
    public record FrameBound(BoundKind kind, Number offset) { }

    public record FrameSpec(FrameMode mode, FrameBound start, FrameBound end) { }

    /** One entry of a WINDOW clause. */
    public record NamedWindow(String name, WindowSpec spec) { }

    // ---- statements ----
    public sealed interface Stmt permits CreateTable, DropTable, Insert, Select, Update, Delete, CreateView, DropView,
        CreateIndex, DropIndex, AlterTable, Transaction { }

    public enum ConstraintKind { PRIMARY_KEY, NOT_NULL, UNIQUE, DEFAULT, COLLATE }

    /** value is the DEFAULT value (null, Long, Double or String), or the collation name for COLLATE; else unused. */
    public record ColumnConstraint(ConstraintKind kind, Object value) { }

    /** constraints are in the order written. */
    public record ColumnDef(String name, SqlType type, List<ColumnConstraint> constraints) { }

    /** A PRIMARY KEY (...) or UNIQUE (...) clause after the column definitions. */
    public record TableConstraint(boolean primaryKey, List<String> columns) { }

    public record CreateTable(String name, boolean ifNotExists, List<ColumnDef> columns,
                              List<TableConstraint> constraints) implements Stmt { }

    public record Assignment(String column, Expr value) { }

    /** where may be null. */
    public record Update(String table, List<Assignment> assignments, Expr where) implements Stmt { }

    /** where may be null. */
    public record Delete(String table, Expr where) implements Stmt { }

    public record DropTable(String name, boolean ifExists) implements Stmt { }

    /** columns is null when no column list was given; exactly one of rows and select is set. */
    public record Insert(String table, List<String> columns, List<List<Expr>> rows, Select select)
        implements Stmt { }

    /** columns is null when no column list was given. The select is not checked until the view is used. */
    public record CreateView(String name, boolean ifNotExists, List<String> columns, Select select)
        implements Stmt { }

    public record DropView(String name, boolean ifExists) implements Stmt { }

    /** An index column; collation is the COLLATE name as written, or null when the column's own applies. */
    public record IndexColumn(String name, String collation) { }

    public record CreateIndex(String name, boolean unique, boolean ifNotExists, String table,
                              List<IndexColumn> columns) implements Stmt { }

    public record DropIndex(String name, boolean ifExists) implements Stmt { }

    /** ALTER TABLE ... ADD / RENAME TO / RENAME COLUMN. */
    public sealed interface Alteration permits AddColumn, RenameTable, RenameColumn { }

    public record AddColumn(ColumnDef column) implements Alteration { }

    public record RenameTable(String newName) implements Alteration { }

    public record RenameColumn(String column, String newName) implements Alteration { }

    public record AlterTable(String table, Alteration change) implements Stmt { }

    public enum TransactionOp { BEGIN, COMMIT, ROLLBACK }

    public record Transaction(TransactionOp op) implements Stmt { }

    /** expr == null means "*", or "q.*" when starOf (the source name q) is set. alias may be null. */
    public record ResultColumn(Expr expr, String alias, String starOf) {
        public ResultColumn(Expr expr, String alias) {
            this(expr, alias, null);
        }
    }

    /** A source in FROM: a table with an optional alias, or a ( select ) with an optional alias. */
    public sealed interface FromItem permits TableRef, SubqueryRef { }

    public record TableRef(String table, String alias) implements FromItem { }

    public record SubqueryRef(Select select, String alias) implements FromItem { }

    public enum JoinKind { CROSS, INNER, LEFT }

    /** One join after the first source; on and using are both null/empty when there is no constraint. */
    public record JoinStep(JoinKind kind, FromItem item, Expr on, List<String> using) { }

    public record FromClause(FromItem first, List<JoinStep> joins) { }

    /** nullsFirst is null when not specified. */
    public record OrderTerm(Expr expr, boolean desc, Boolean nullsFirst) { }

    /** name = (select), with the optional column list; columns is null when absent. */
    public record Cte(String name, List<String> columns, Select select) { }

    /** A WITH clause (5.2). */
    public record With(boolean recursive, List<Cte> ctes) { }

    /**
     * One simple select (no ORDER BY / LIMIT of its own). from, where, having may be null; groupBy is
     * empty when there is no GROUP BY. distinct is SELECT DISTINCT. windows is its WINDOW clause (6.1).
     */
    public record SelectCore(boolean distinct, List<ResultColumn> columns, FromClause from, Expr where,
                             List<Expr> groupBy, Expr having, List<NamedWindow> windows) { }

    public enum CompoundOp {
        UNION_ALL("UNION ALL"), UNION("UNION"), INTERSECT("INTERSECT"), EXCEPT("EXCEPT");

        public final String text;

        CompoundOp(String text) {
            this.text = text;
        }
    }

    public record CompoundTerm(CompoundOp op, SelectCore select) { }

    /**
     * A whole select (5.1): first, then rest combined left to right, and the ORDER BY / LIMIT / OFFSET of
     * the result. with and limit and offset may be null.
     */
    public record Select(With with, SelectCore first, List<CompoundTerm> rest, List<OrderTerm> orderBy,
                         Expr limit, Expr offset) implements Stmt { }
}
