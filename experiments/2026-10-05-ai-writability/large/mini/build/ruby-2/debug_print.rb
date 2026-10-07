require_relative "ast"
require_relative "text"

module Mini
  # The --tokens and --ast outputs (section 1). Their format is meant for
  # debugging the implementation and is not part of the language.
  module DebugPrint
    include AST
    module_function

    # One line per token: "line:col type text"; interpolations are indented
    # under their string.
    def tokens(tokens, indent = "")
      tokens.map do |token|
        text = token.type == :newline ? "\\n" : token.text
        line = "#{indent}#{token.line}:#{token.col} #{token.type} #{text}".rstrip + "\n"
        next line unless token.type == :string
        line + token.parts.grep(Array).map { |part| tokens(part, indent + "  ") }.join
      end.join
    end

    # One statement per line; nested statements indented by two spaces under
    # a label naming the block.
    def program(statements) = block(statements, "")

    def block(statements, indent)
      statements.map { |stmt| statement(stmt, indent) }.join
    end

    def statement(stmt, indent)
      nested = indent + "  "
      head, blocks =
        case stmt
        when Let then ["(let #{stmt.name.text}#{stmt.value ? " #{expr(stmt.value)}" : ""})", []]
        when LetArray then ["(let [#{stmt.names.map(&:text).join(" ")}] #{expr(stmt.value)})", []]
        when Const then ["(const #{stmt.name.text} #{expr(stmt.value)})", []]
        when FnDecl then ["(fn #{stmt.name.text} #{params(stmt.function)})", [["body", stmt.function.body]]]
        when If
          branches = stmt.branches.map { |condition, body| ["when #{expr(condition)}", body] }
          ["(if)", branches + (stmt.else_body ? [["else", stmt.else_body]] : [])]
        when Match
          arms = stmt.arms.map { |values, body| ["when #{values.map { |v| expr(v) }.join(" ")}", body] }
          ["(match #{expr(stmt.subject)})", arms + (stmt.else_body ? [["else", stmt.else_body]] : [])]
        when While then ["(while #{expr(stmt.condition)})", [["do", stmt.body]]]
        when For then ["(for #{stmt.names.map(&:text).join(" ")} #{expr(stmt.iterable)})", [["do", stmt.body]]]
        when Break then ["(break)", []]
        when Continue then ["(continue)", []]
        when Return then ["(return#{stmt.value ? " #{expr(stmt.value)}" : ""})", []]
        when Throw then ["(throw #{expr(stmt.value)})", []]
        when Assert then ["(assert #{[stmt.condition, stmt.message].compact.map { |e| expr(e) }.join(" ")})", []]
        when Try
          blocks = [["try", stmt.body]]
          blocks << ["catch #{stmt.catch_name.text}", stmt.catch_body] if stmt.catch_body
          blocks << ["finally", stmt.finally_body] if stmt.finally_body
          ["(try)", blocks]
        when Assign
          ["(#{stmt.op} (#{stmt.targets.map { |t| expr(t) }.join(" ")}) (#{stmt.values.map { |v| expr(v) }.join(" ")}))", []]
        when ExprStmt then [expr(stmt.expr), []]
        end
      lines = "#{indent}#{head}\n"
      blocks.each { |label, body| lines += "#{nested}#{label}:\n" + block(body, nested + "  ") }
      lines
    end

    def params(function)
      "(" + function.params.map { |p| p.default ? "(#{p.name.text} #{expr(p.default)})" : p.name.text }.join(" ") + ")"
    end

    def expr(node)
      case node
      when Literal then Text.repr(node.value)
      when StringLit
        "(str " + node.parts.map { |part| part.is_a?(String) ? Text.repr(part) : expr(part) }.join(" ") + ")"
      when Name then "(name #{node.name} @#{node.depth})"
      when ArrayLit then "(array #{node.elements.map { |e| expr(e) }.join(" ")})".sub(" )", ")")
      when MapLit then "(map #{node.entries.map { |k, v| "#{expr(k)} #{expr(v)}" }.join(" ")})".sub(" )", ")")
      when Function then "(fn #{params(node)} #{program(node.body).lines.map(&:strip).join(" ")})"
      when Unary then "(#{node.op} #{expr(node.operand)})"
      when Binary, Logical then "(#{node.op} #{expr(node.left)} #{expr(node.right)})"
      when Call then "(call #{expr(node.callee)}#{node.args.map { |a| " #{expr(a)}" }.join})"
      when Index then "(index #{expr(node.object)} #{expr(node.index)})"
      when Slice then "(slice #{expr(node.object)} #{node.from ? expr(node.from) : "nil"} #{node.to ? expr(node.to) : "nil"})"
      when Field then "(field #{expr(node.object)} #{node.name})"
      end
    end
  end
end
