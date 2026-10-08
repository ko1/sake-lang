package sqlengine.parse;

import java.util.List;
import sqlengine.value.SqlType;

/** Syntax trees produced by Parser. Names are kept as written; resolution happens in exec. */
public final class Ast {
    private Ast() { }

    // ---- expressions ----
    public sealed interface Expr permits Literal, Name, Unary, Binary, Is, Call { }

    /** value: null, Long, Double or String. */
    public record Literal(Object value) implements Expr { }

    public record Name(String name) implements Expr { }

    /** op: "-", "+" or "NOT". */
    public record Unary(String op, Expr operand) implements Expr { }

    /** op: + - * / % || = != < <= > >= AND OR ("==" and "<>" are normalised to "=" and "!="). */
    public record Binary(String op, Expr left, Expr right) implements Expr { }

    public record Is(Expr left, Expr right, boolean negated) implements Expr { }

    public record Call(String name, List<Expr> args) implements Expr { }

    // ---- statements ----
    public sealed interface Stmt permits CreateTable, DropTable, Insert, Select { }

    public record ColumnDef(String name, SqlType type) { }

    public record CreateTable(String name, boolean ifNotExists, List<ColumnDef> columns) implements Stmt { }

    public record DropTable(String name, boolean ifExists) implements Stmt { }

    /** columns is null when no column list was given. */
    public record Insert(String table, List<String> columns, List<List<Expr>> rows) implements Stmt { }

    /** expr == null means "*". alias may be null. */
    public record ResultColumn(Expr expr, String alias) { }

    /** nullsFirst is null when not specified. */
    public record OrderTerm(Expr expr, boolean desc, Boolean nullsFirst) { }

    /** from, where, limit, offset may be null. */
    public record Select(List<ResultColumn> columns, String from, Expr where, List<OrderTerm> orderBy,
                         Expr limit, Expr offset) implements Stmt { }
}
