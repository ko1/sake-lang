# Text dumps of tokens and of the resolved AST, for `main.rb --tokens` and
# `main.rb --ast` (SPEC.md, "Running"). Expressions are written as
# S-expressions on one line; each statement starts a line, indented by its
# nesting. A Name shows the depth the resolver gave it: (name x @1).
module Debug
  module_function

  # One line per token: "line:col type text", with an interpolation's tokens
  # indented below it.
  def tokens(toks, indent = "")
    lines = []
    toks.each do |tok|
      lines.push("#{indent}#{tok.pos} #{token_text(tok)}")
      next unless tok.type == :interp

      tok.value.each do |part|
        if part.is_a?(String)
          lines.push("#{indent}  part #{Format.quote(part)}")
        else
          lines.concat(tokens(part, "#{indent}  "))
        end
      end
    end
    lines
  end

  def token_text(tok)
    case tok.type
    when :int then "int #{tok.value}"
    when :float then "float #{tok.text}"
    when :str then "str #{Format.quote(tok.value)}"
    when :interp then "interp"
    when :newline then "newline"
    when :eof then tok.text == "" ? "eof" : "eof }"
    else "#{tok.type} #{tok.text}"
    end
  end

  def program(prog) = statements(prog.body, "").join("\n")

  def statements(stmts, indent)
    lines = []
    stmts.each { |stmt| lines.concat(statement(stmt, indent)) }
    lines
  end

  # The lines of one statement, the nested statement lists indented further.
  def statement(stmt, indent)
    inner = "#{indent}  "
    case stmt
    when ExprStmt then ["#{indent}#{expression(stmt.expr)}"]
    when Let
      value = stmt.value.nil? ? "" : " #{expression(stmt.value)}"
      ["#{indent}(let #{stmt.name}#{value})"]
    when LetList then ["#{indent}(let [#{param_names(stmt.names)}] #{expression(stmt.value)})"]
    when Const then ["#{indent}(const #{stmt.name} #{expression(stmt.value)})"]
    when FnDecl then ["#{indent}(fn-decl #{stmt.fn.name} (#{params(stmt.fn.params)})"] + statements(stmt.fn.body, inner)
    when Assign then ["#{indent}(#{stmt.op} #{expression(stmt.target)} #{expression(stmt.value)})"]
    when MultiAssign
      ["#{indent}(= [#{expressions(stmt.targets)}] [#{expressions(stmt.values)}])"]
    when If
      lines = []
      stmt.branches.each_index do |i|
        lines.push("#{indent}(#{i == 0 ? "if" : "elif"} #{expression(stmt.branches[i].cond)})")
        lines.concat(statements(stmt.branches[i].body, inner))
      end
      lines + else_lines(stmt.else_body, indent)
    when Match
      lines = ["#{indent}(match #{expression(stmt.subject)})"]
      stmt.arms.each do |arm|
        lines.push("#{indent}(when #{expressions(arm.values)})")
        lines.concat(statements(arm.body, inner))
      end
      lines + else_lines(stmt.else_body, indent)
    when While then ["#{indent}(while #{expression(stmt.cond)})"] + statements(stmt.body, inner)
    when For
      ["#{indent}(for #{param_names(stmt.vars)} #{expression(stmt.iterable)})"] + statements(stmt.body, inner)
    when Break then ["#{indent}(break)"]
    when Continue then ["#{indent}(continue)"]
    when Return then ["#{indent}(return#{stmt.value.nil? ? "" : " #{expression(stmt.value)}"})"]
    when Throw then ["#{indent}(throw #{expression(stmt.value)})"]
    when Assert
      message = stmt.message.nil? ? "" : " #{expression(stmt.message)}"
      ["#{indent}(assert #{expression(stmt.cond)}#{message})"]
    when Try then try_lines(stmt, indent)
    else raise ArgumentError, "unknown statement #{stmt.class}"
    end
  end

  def else_lines(body, indent)
    return [] if body.nil?

    ["#{indent}(else)"] + statements(body, "#{indent}  ")
  end

  def try_lines(stmt, indent)
    inner = "#{indent}  "
    lines = ["#{indent}(try)"] + statements(stmt.body, inner)
    lines = lines + ["#{indent}(catch #{stmt.var.name})"] + statements(stmt.handler, inner) unless stmt.var.nil?
    lines = lines + ["#{indent}(finally)"] + statements(stmt.finally_body, inner) unless stmt.finally_body.nil?
    lines
  end

  def param_names(params) = params.map { |param| param.name }.join(" ")

  def params(params)
    params.map { |param| param.default.nil? ? param.name : "#{param.name}=#{expression(param.default)}" }.join(" ")
  end

  def expressions(nodes) = nodes.map { |node| expression(node) }.join(" ")

  def expression(node)
    case node
    when IntLit then node.value.to_s
    when FloatLit then Format.repr(node.value)
    when StrLit then Format.quote(node.value)
    when InterpStr
      parts = node.parts.map { |part| part.is_a?(String) ? Format.quote(part) : expression(part) }
      "(interp #{parts.join(" ")})"
    when BoolLit then node.value.to_s
    when NilLit then "nil"
    when Name then "(name #{node.name} @#{node.depth.nil? ? "?" : node.depth})"
    when ArrayLit then "[#{expressions(node.elements)}]"
    when MapLit
      entries = (0...node.keys.length).map { |i| "#{expression(node.keys[i])}: #{expression(node.values[i])}" }
      "{#{entries.join(", ")}}"
    when FnExpr then "(fn (#{params(node.params)})#{statements(node.body, " ").join(";")})"
    when Unary then "(#{node.op} #{expression(node.operand)})"
    when Binary, Logical then "(#{node.op} #{expression(node.left)} #{expression(node.right)})"
    when Call then "(call #{expression(node.callee)}#{node.args.empty? ? "" : " "}#{expressions(node.args)})"
    when Index then "(index #{expression(node.target)} #{expression(node.index)})"
    when Slice
      bounds = [node.start, node.stop].map { |bound| bound.nil? ? "_" : expression(bound) }
      "(slice #{expression(node.target)} #{bounds.join(" ")})"
    else raise ArgumentError, "unknown expression #{node.class}"
    end
  end
end
