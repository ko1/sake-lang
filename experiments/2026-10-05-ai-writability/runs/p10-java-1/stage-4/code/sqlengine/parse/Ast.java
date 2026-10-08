package sqlengine.parse;

import java.util.List;
import sqlengine.value.SqlType;

/** Syntax trees produced by Parser. Names are kept as written; resolution happens in exec. */
public final class Ast {
    private Ast() { }

    // ---- expressions ----
    public sealed interface Expr permits Literal, Name, Unary, Binary, Is, Call, Case, Between, In, Like, Cast,
        Subquery, Exists, InSelect { }

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

    /** A scalar subquery (4.3). */
    public record Subquery(Select select) implements Expr { }

    public record Exists(Select select, boolean negated) implements Expr { }

    public record InSelect(Expr value, Select select, boolean negated) implements Expr { }

    // ---- statements ----
    public sealed interface Stmt permits CreateTable, DropTable, Insert, Select, Update, Delete { }

    public enum ConstraintKind { PRIMARY_KEY, NOT_NULL, UNIQUE, DEFAULT }

    /** value is the DEFAULT value (null, Long, Double or String) and unused for the other kinds. */
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

    /** columns is null when no column list was given. */
    public record Insert(String table, List<String> columns, List<List<Expr>> rows) implements Stmt { }

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

    /**
     * from, where, having, limit, offset may be null; groupBy is empty when there is no GROUP BY.
     * distinct is SELECT DISTINCT.
     */
    public record Select(boolean distinct, List<ResultColumn> columns, FromClause from, Expr where,
                         List<Expr> groupBy, Expr having, List<OrderTerm> orderBy,
                         Expr limit, Expr offset) implements Stmt { }
}
