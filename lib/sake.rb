# frozen_string_literal: true

require "prism"
require_relative "sake/errors"
require_relative "sake/values"
require_relative "sake/registry"
require_relative "sake/operators"
require_relative "sake/stdlib"
require_relative "sake/stdlib_ext"
require_relative "sake/stdlib_table"
require_relative "sake/stdlib_net"
require_relative "sake/stdlib_text"
require_relative "sake/stdlib_io"
require_relative "sake/stdlib_core"
require_relative "sake/resolver"
require_relative "sake/interpreter"

module Sake
  # Libraries that `require "name"` finds when no file of that name is next to the requiring file.
  SAKELIB = File.expand_path("../sakelib", __dir__)

  module_function

  # Parses and resolves; raises StaticErrors with every problem found. `require "lib/x"` (a string
  # literal, at the top level of a file) reads lib/x.sake next to the requiring file, once; the
  # required files come first, as their top-level statements run before the requiring file's.
  def load(source, path, out: $stdout, input: $stdin)
    Sake.program_name = path
    files = [] # [path, ProgramNode], required files before the files that require them
    sources = {}.compare_by_identity # Prism source => path, to name the file of any node
    diags = []
    seen = { File.expand_path(path) => true }
    visit = lambda do |file, src|
      result = Prism.parse(src, filepath: file)
      unless result.errors.empty?
        lines = src.lines
        result.errors.each do |e|
          # `x in T` binds loosely (Ruby's grammar): `f(a, x in T)` and `x in T ? a : b` do not parse as meant.
          hint = lines[e.location.start_line - 1].to_s.match?(/\b\w+ in [A-Z]/) ? ["`x in T` needs its own parentheses here: `(x in T)`"] : []
          diags << Diagnostic.new(file, e.location.start_line, e.location.start_column, "syntax error: #{e.message}", hint)
        end
        next
      end
      root = result.value
      sources[root.location.send(:source)] = file
      root.statements.body.each do |st|
        next unless Resolver.require_call?(st)
        loc = st.location
        arg = st.arguments&.arguments
        unless arg&.size == 1 && arg[0].is_a?(Prism::StringNode)
          diags << Diagnostic.new(file, loc.start_line, loc.start_column, "require takes one string literal, as in `require \"lib/web\"`",
                                  ["the file is decided before running, so it cannot be a variable or an expression"])
          next
        end
        name = arg[0].unescaped
        name += ".sake" if File.extname(name).empty?
        target = File.dirname(file) == "." || File.absolute_path?(name) ? name : File.join(File.dirname(file), name)
        # Not next to the requiring file: Sake's own library (sakelib/), as Ruby's standard library.
        # The requiring file itself is never the one meant (test/sakelib/csv.sake requiring "csv"), nor is a
        # sibling that is a program rather than a library (test/sakelib/net_http.sake next to another test).
        if File.exist?(File.join(SAKELIB, name)) &&
           (!File.exist?(target) || File.expand_path(target) == File.expand_path(file) || !library_file?(target))
          target = File.join(SAKELIB, name)
        end
        next if seen[File.expand_path(target)]
        seen[File.expand_path(target)] = true
        text = begin
          File.read(target)
        rescue SystemCallError => e
          diags << Diagnostic.new(file, loc.start_line, loc.start_column, "require: cannot read #{target} (#{e.class.name.split("::").last})", [])
          next
        end
        visit.(target, text)
      end
      files << [file, root]
    end
    visit.(path, source)
    raise StaticErrors.new(diags) unless diags.empty?
    registry = Registry.new
    Stdlib.install(registry, out)
    Stdlib.install_ext(registry, out, input)
    Resolver.new(path, files, registry, sources).resolve
  end

  # Whether a file is a library: its top level holds only definitions (class, module, def, `X = Struct.new`)
  # and requires. A file that also runs something is a program, which a `require` next to it does not mean.
  def library_file?(path)
    result = Prism.parse(File.read(path), filepath: path)
    return true unless result.errors.empty?
    result.value.statements.body.all? do |st|
      case st
      when Prism::ClassNode, Prism::ModuleNode, Prism::DefNode, Prism::ConstantWriteNode then true
      when Prism::CallNode then Resolver.require_call?(st)
      else false
      end
    end
  rescue SystemCallError
    true
  end

  # The file a Prism node (or a SakeAST node) comes from.
  # Whether a call's target must get a block (a passed-on `&b` may carry none).
  def needs_block?(call)
    case call
    when AST::CallBuiltin then call.fn.block == :required
    when AST::CallUser then !call.fn.block_optional
    when AST::CallDispatch then call.dispatch.table.values.any? { _1.is_a?(UserFunction) ? !_1.block_optional : _1.block == :required }
    when AST::CallUnion then call.union.table.values.any? { _1.is_a?(UserFunction) ? !_1.block_optional : _1.block == :required }
    end
  end

  def file_of(program, node)
    node = node.origin if node.respond_to?(:origin)
    program.sources[node.location.send(:source)] || program.path
  end

  # A thread that ended with an error nobody read (no Thread.value / Thread.join) is reported on stderr at exit,
  # as Ruby reports it when the thread dies; the program's own exit status is not changed.
  def report_dead_threads(path)
    $stdout.flush if Sake.dead_threads.any? # the program's output first, then the report
    Sake.dead_threads.each do |_, e|
      e.path ||= path
      $stderr.puts("#{e.path}: a thread ended with an error that no Thread.value / Thread.join read:", e.report.gsub(/^/, "  "))
    end
    Sake.dead_threads.clear
  end

  # The program runs in its own thread: bin/sake sizes thread stacks (RUBY_THREAD_*_STACK_SIZE)
  # so that Sake's own depth limit, not Ruby's stack, bounds recursion.
  def run(source, path, out: $stdout) = execute(load(source, path, out:))

  def execute(program, thread: true)
    path = program.path
    unless thread
      Sake.at_exit_blocks.clear
      Sake.dead_threads.clear
      begin
        return Interpreter.new(program).run
      ensure
        Sake.at_exit_blocks.reverse_each(&:call)
        report_dead_threads(path)
      end
    end
    Sake.at_exit_blocks.clear
    Sake.dead_threads.clear
    th = Thread.new do
      begin
        Interpreter.new(program).run
      ensure
        Sake.at_exit_blocks.reverse_each(&:call) # Kernel.at_exit, last registered first, after a normal end, exit, or an error
        report_dead_threads(path)
      end
    end
    th.report_on_exception = false
    th.value
  rescue RunError => e
    e.path = path
    raise
  rescue Exception => e # rubocop:disable Lint/RescueException -- Ruby's `fatal` (a deadlock) is not a StandardError
    raise unless e.class.name == "fatal" && e.message.include?("Deadlock")
    err = RunError.new("ThreadError", "deadlock: every thread is waiting (a Queue.pop with nothing left to push, " \
                                      "a Mutex.synchronize inside itself, or a Thread.join on a thread waiting for this one)", 0)
    err.path = path
    raise err
  end
end
