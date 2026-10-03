# frozen_string_literal: true

require "json"
require "stringio"
require_relative "cli"
require_relative "typer"

module Sake
  # The browser IDE's side of Sake (ide/): requests and answers are JSON strings. It runs on ruby.wasm,
  # where there are no threads. Columns in answers count characters, as the editor does.
  module IDE
    PATH = "main.sake"
    KEYWORDS = %w[def end if elsif else unless while until case in then do begin rescue ensure return next break
                  yield raise class module include true false nil and or not self].freeze

    module_function

    def dispatch(json)
      req = JSON.parse(json.to_s)
      res =
        case req["cmd"]
        when "run" then run(req["src"].to_s, req["level"].to_i, req["stdin"].to_s)
        when "analyze" then analyze(req["src"].to_s, req["level"].to_i)
        when "catalog" then catalog
        else { error: "unknown command #{req["cmd"]}" }
        end
      JSON.generate(res)
    rescue StandardError, SystemStackError => e
      JSON.generate(error: "#{e.class}: #{e.message}", backtrace: e.backtrace&.first(8))
    end

    # What `sake --strict=LEVEL main.sake` prints, with stdin as the program's input.
    def run(src, level, stdin)
      out = StringIO.new
      err = StringIO.new
      saved = $stdin
      $stdin = StringIO.new(stdin)
      status = CLI.run_source(src, PATH, items: CLI::STRICT_LEVELS.fetch(level), out:, err:, thread: false)
      { stdout: out.string, stderr: err.string, status: }
    ensure
      $stdin = saved
    end

    # Diagnostics (errors at the chosen level, warnings for the items above it), the inferred types for
    # hovers and the Types view, and the SakeAST.
    def analyze(src, level)
      res = { diagnostics: [], hovers: [], functions: [], fields: [], arrays: [], ast: nil, summary: nil, symbols: symbols(src) }
      program =
        begin
          Sake.load(src, PATH, out: StringIO.new, input: StringIO.new)
        rescue StaticErrors => e
          res[:diagnostics] = e.diagnostics.map { diagnostic(_1, src, "error") }
          return res
        end
      code = Lower.program(program)
      res[:ast] = [AST.dump(code.main), *code.functions.each_value.map { AST.dump(_1) }].join("\n")
      typer = Recorder.new(program).run
      items = CLI::STRICT_LEVELS.fetch(level)
      # Only the editor's file: a required library's own warnings are not the program's to fix.
      res[:diagnostics] = CLI.strict_diagnostics(program, CLI::STRICT_ITEMS, typer).select { _1.path == PATH }.map do |d|
        item = d.message[/\[([\w-]+)\]\z/, 1]
        diagnostic(d, src, items.include?(item) ? "error" : "warning", level: CLI::STRICT_LEVELS.index { _1.include?(item) })
      end
      res[:hovers] = typer.hovers
      res[:functions] = typer.signatures
      res[:fields] = typer.fields.flat_map { |dt, fs| fs.map { |f, ty| { type: dt, field: f, inferred: typer.show(ty) } } }
      res[:arrays] = typer.sites.values.map { |s| { label: s.label, elem: s.declared || typer.show(s.elem) } }
      res[:summary] = typer.summary.transform_keys(&:to_s)
      res
    end

    def diagnostic(d, src, severity, level: nil)
      # An error in a required file shows on the first line, naming the file.
      return { line: 1, col: 0, message: "#{File.basename(d.path)}:#{d.line}: #{d.message}", hints: d.hints, severity:, level: } if d.path != PATH

      { line: d.line, col: char_column(src, d.line, d.column), message: d.message, hints: d.hints, severity:, level: }
    end

    def char_column(src, line, byte_col)
      text = src.lines[line - 1] or return byte_col
      text.byteslice(0, byte_col).to_s.dup.force_encoding(Encoding::UTF_8).scrub.length
    end

    # The built-in operations by namespace, for completion.
    def catalog
      reg = Registry.new
      Stdlib.install(reg, StringIO.new)
      Stdlib.install_ext(reg, StringIO.new, StringIO.new)
      namespaces = reg.namespaces.sort.to_h do |ns|
        ops = reg.names(ns).sort.filter_map do |n|
          next unless n == CTOR || n.match?(/\A[a-z_]\w*[?!]?\z/) # operators are written as operators
          b = reg.lookup(ns, n)
          { name: n == CTOR ? "[]" : n, signature: b.signature, block: b.block.to_s }
        end
        [ns, ops]
      end
      { namespaces:, modules: Operators::MODULE_OF.values.uniq.sort, exceptions: Resolver::BUILTIN_EXCEPTIONS.reject { _1.include?("::") },
        keywords: KEYWORDS }
    end

    # The program's own names, read from the syntax tree (also when it does not resolve): types with their
    # fields and functions, top-level functions, and local variable names.
    def symbols(src)
      types = {}
      functions = []
      locals = []
      add_type = ->(name, kind) { types[name] ||= { kind:, fields: [], functions: [] } }
      walk = lambda do |n, owner|
        return unless n
        case n
        when Prism::ClassNode, Prism::ModuleNode
          name = n.constant_path.slice
          t = add_type.(name, n.is_a?(Prism::ModuleNode) ? "module" : "class")
          if n.is_a?(Prism::ClassNode) && n.superclass.is_a?(Prism::HashNode) # class C < {accessor: [x, y]}
            n.superclass.elements.each do |el|
              next unless el.respond_to?(:value) && el.value.is_a?(Prism::ArrayNode)
              el.value.elements.each { |f| t[:fields] |= [f.slice.delete_prefix(":")] }
            end
          end
          return walk.(n.body, name)
        when Prism::ConstantWriteNode
          v = n.value
          if v.is_a?(Prism::CallNode) && v.name == :new && v.receiver.is_a?(Prism::ConstantReadNode) && %i[Struct Exception].include?(v.receiver.name)
            t = add_type.(n.name.to_s, v.receiver.name == :Struct ? "struct" : "exception")
            (v.arguments&.arguments || []).each { |a| t[:fields] |= [a.unescaped] if a.is_a?(Prism::SymbolNode) }
          end
        when Prism::DefNode
          params = n.parameters ? n.parameters.requireds.map { _1.respond_to?(:name) ? _1.name.to_s : _1.slice } : []
          f = { name: n.name.to_s, params:, line: n.location.start_line }
          owner ? types[owner][:functions] << f : functions << f
          params.each { locals |= [_1] }
        when Prism::LocalVariableWriteNode, Prism::LocalVariableTargetNode, Prism::RequiredParameterNode
          locals |= [n.name.to_s]
        end
        n.compact_child_nodes.each { walk.(_1, owner) }
      end
      walk.(Prism.parse(src).value, nil)
      { types:, functions:, locals: }
    end

    # The typer, keeping the inferred type of every expression and the signatures of user functions
    # (of the last pass: earlier passes see tables that are still growing).
    class Recorder < Typer
      CALLS = [AST::CallBuiltin, AST::CallUser, AST::CallDispatch, AST::CallUnion, AST::UnOp, AST::BinOp, AST::IsNil,
               AST::IndexGet, AST::IndexSet, AST::FieldGet, AST::FieldSet, AST::LVarGet, AST::LVarSet, AST::Yield].freeze

      def ev(node, env)
        reset_records if @rec_pass != @passes
        r = super
        o = node.origin
        primary =
          case o
          when Prism::LocalVariableReadNode, Prism::ItLocalVariableReadNode then node.is_a?(AST::LVarGet)
          when Prism::LocalVariableWriteNode, Prism::LocalVariableOperatorWriteNode then node.is_a?(AST::LVarSet)
          when Prism::InstanceVariableReadNode then node.is_a?(AST::FieldGet)
          when Prism::CallNode then CALLS.include?(node.class)
          when Prism::YieldNode then node.is_a?(AST::Yield)
          end
        @rec[o] = Typer.union(@rec[o] || [], r) if primary
        r
      end

      def call_user(fn, args, blk)
        reset_records if @rec_pass != @passes
        r = super
        (@fn_args[fn] ||= Array.new(args.size) { [] }).each_index { |i| @fn_args[fn][i] = Typer.union(@fn_args[fn][i], args[i] || []) }
        @fn_rets[fn] = Typer.union(@fn_rets[fn] || [], r)
        r
      end

      def reset_records
        @rec_pass = @passes
        @rec = {}.compare_by_identity
        @fn_args = {}.compare_by_identity
        @fn_rets = {}.compare_by_identity
      end

      def hovers
        reset_records unless @rec
        @rec.filter_map do |o, ty|
          next if ty.empty? || Sake.file_of(@program, o) != PATH
          loc = hover_location(o)
          { from: [loc.start_line, loc.start_character_column], to: [loc.end_line, loc.end_character_column], type: show(ty) }
        end
      end

      # The variable's name for a write; the operation's name for `T.op(...)`; else the whole expression.
      def hover_location(o)
        return o.name_loc if o.is_a?(Prism::LocalVariableWriteNode) || o.is_a?(Prism::LocalVariableOperatorWriteNode)
        return o.message_loc if o.is_a?(Prism::CallNode) && o.receiver && o.message_loc && o.call_operator_loc
        o.location
      end

      def signatures
        reset_records unless @rec
        @fn_args.keys.select { Sake.file_of(@program, _1.node) == PATH }.map do |fn|
          { name: fn.full_name, line: fn.node.location.start_line,
            params: fn.params.each_with_index.map { |p, i| [p.to_s, show(@fn_args[fn][i] || [])] },
            returns: show(@fn_rets[fn] || []) }
        end.sort_by { _1[:line] }
      end
    end
  end
end
