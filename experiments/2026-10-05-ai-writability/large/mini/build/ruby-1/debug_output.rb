# frozen_string_literal: true

require_relative "ast"
require_relative "text"

module Mini
  # The `--tokens` and `--ast` listings (SPEC section 1). Their format is for
  # debugging only and not part of the language.
  module DebugOutput
    include AST

    module_function

    # `line:col type text`, an interpolation's tokens indented under their string.
    def write_tokens(tokens, out, indent = 0)
      tokens.each do |token|
        out.puts("#{"  " * indent}#{token.position} #{token.type} #{token.text}")
        next unless token.type == :string

        token.value.each { |part| write_tokens(part, out, indent + 1) if part.is_a?(Array) }
      end
    end

    # One statement per line, nested statements indented by two spaces.
    def write_ast(program, out)
      write_body(program.body, out, 0)
    end

    def write_body(body, out, indent)
      body.each { |stmt| write_statement(stmt, out, indent) }
    end

    def line(out, indent, text) = out.puts("#{"  " * indent}#{text}")

    # A statement with nested blocks: a header, then each labelled block.
    def write_compound(out, indent, header, blocks)
      line(out, indent, "(#{header}")
      blocks.each do |label, body|
        line(out, indent + 1, "(#{label}")
        write_body(body, out, indent + 2)
        line(out, indent + 1, ")")
      end
      line(out, indent, ")")
    end

    def write_statement(stmt, out, indent)
      case stmt
      when Let then line(out, indent, "(let #{stmt.name.text}#{stmt.value ? " #{sexp(stmt.value)}" : ""})")
      when LetArray then line(out, indent, "(let [#{stmt.names.map(&:text).join(" ")}] #{sexp(stmt.value)})")
      when Const then line(out, indent, "(const #{stmt.name.text} #{sexp(stmt.value)})")
      when FnDecl
        write_compound(out, indent, "fn #{stmt.name.text} #{params(stmt.function)}", [["body", stmt.function.body]])
      when If
        blocks = stmt.branches.map { |b| ["when #{sexp(b.condition)}", b.body] }
        blocks << ["else", stmt.else_body] if stmt.else_body
        write_compound(out, indent, "if", blocks)
      when Match
        blocks = stmt.arms.map { |a| ["when #{a.values.map { |v| sexp(v) }.join(" ")}", a.body] }
        blocks << ["else", stmt.else_body] if stmt.else_body
        write_compound(out, indent, "match #{sexp(stmt.subject)}", blocks)
      when While then write_compound(out, indent, "while #{sexp(stmt.condition)}", [["body", stmt.body]])
      when For
        names = stmt.names.map(&:text).join(" ")
        write_compound(out, indent, "for #{names} #{sexp(stmt.iterable)}", [["body", stmt.body]])
      when Break then line(out, indent, "(break)")
      when Continue then line(out, indent, "(continue)")
      when Return then line(out, indent, stmt.value ? "(return #{sexp(stmt.value)})" : "(return)")
      when Throw then line(out, indent, "(throw #{sexp(stmt.value)})")
      when Assert
        line(out, indent, "(assert #{sexp(stmt.condition)}#{stmt.message ? " #{sexp(stmt.message)}" : ""})")
      when Try
        blocks = [["body", stmt.body]]
        blocks << ["catch #{stmt.catch_name.text}", stmt.catch_body] if stmt.catch_body
        blocks << ["finally", stmt.finally_body] if stmt.finally_body
        write_compound(out, indent, "try", blocks)
      when Assign then line(out, indent, "(#{stmt.operator} #{sexp(stmt.target)} #{sexp(stmt.value)})")
      when MultiAssign
        targets = stmt.targets.map { |t| sexp(t) }.join(" ")
        line(out, indent, "(= (#{targets}) (#{stmt.values.map { |v| sexp(v) }.join(" ")}))")
      when ExprStmt then line(out, indent, sexp(stmt.expression))
      end
    end

    def params(function)
      list = function.params.map { |p| p.default ? "(#{p.name.text} #{sexp(p.default)})" : p.name.text }
      "(#{list.join(" ")})"
    end

    def sexp(node)
      case node
      when Literal then Text.repr(node.value)
      when Name then "(name #{node.text} @#{node.depth})"
      when Interpolation
        parts = node.parts.map { |part| part.is_a?(String) ? Text.repr(part) : sexp(part) }
        "(interp #{parts.join(" ")})"
      when ArrayLit then "(array #{node.elements.map { |e| sexp(e) }.join(" ")})"
      when MapLit then "(map #{node.entries.map { |e| "(#{sexp(e.key)} #{sexp(e.value)})" }.join(" ")})"
      when FunctionLit then "(fn #{params(node)} ...)"
      when Negate then "(neg #{sexp(node.operand)})"
      when Not then "(not #{sexp(node.operand)})"
      when Binary, Logical then "(#{node.operator} #{sexp(node.left)} #{sexp(node.right)})"
      when Call then "(call #{sexp(node.callee)} #{node.arguments.map { |a| sexp(a) }.join(" ")})"
      when Index then "(index #{sexp(node.object)} #{sexp(node.index)})"
      when Slice
        "(slice #{sexp(node.object)} #{node.from ? sexp(node.from) : "_"} #{node.to ? sexp(node.to) : "_"})"
      when Field then "(field #{sexp(node.object)} #{node.name})"
      end
    end
  end
end
