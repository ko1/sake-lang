# frozen_string_literal: true

require "prism"
require "stringio"
require_relative "sake/errors"
require_relative "sake/values"
require_relative "sake/registry"
require_relative "sake/operators"
require_relative "sake/stdlib"
require_relative "sake/stdlib_ext"
require_relative "sake/stdlib_table"
require_relative "sake/stdlib_net"
require_relative "sake/stdlib_sqlite3"
require_relative "sake/stdlib_text"
require_relative "sake/stdlib_io"
require_relative "sake/stdlib_core"
require_relative "sake/resolver"
require_relative "sake/interpreter"

module Sake
  # Libraries that `require "name"` finds when no file of that name is next to the requiring file.
  SAKELIB = File.expand_path("../sakelib", __dir__)
  PRELUDE = File.join(SAKELIB, "prelude.sake") # read before every program: Enum

  module_function

  # Parses and resolves; raises StaticErrors with every problem found. `require "lib/x"` (a string
  # literal, at the top level of a file) reads lib/x.sake next to the requiring file, once; the
  # required files come first, as their top-level statements run before the requiring file's.
  #
  # `generate "gen", "arg", ...` (string literals, at the top level of a file) is stage 0: the generator gen.sake is
  # loaded, checked (by `generator`) and run first with the arguments as its ARGV, and what it prints is parsed and
  # joined into the program as if required, under the name "(generate at FILE:LINE)". It cannot see the program.
  # generated: when an Array, gets [site, generator path, args, source] for each generated source.
  def load(source, path, out: $stdout, input: $stdin, generator: nil, generated: nil)
    Sake.program_name = path
    generator ||= method(:run_generator)
    files = [] # [path, ProgramNode], required files before the files that require them
    sources = {}.compare_by_identity # Prism source => path, to name the file of any node
    diags = []
    seen = { File.expand_path(path) => true }
    visit = lambda do |file, src, dir = File.dirname(file)|
      result = Prism.parse(src, filepath: file)
      unless result.errors.empty?
        lines = src.lines
        result.errors.each do |e|
          # `x in T` binds loosely (Ruby's grammar): `f(a, x in T)` and `x in T ? a : b` do not parse as meant.
          hint = lines[e.location.start_line - 1].to_s.match?(/\b\w+ in [A-Z]/) ? ["`x in T` needs its own parentheses here: `(x in T)`"] : []
          # As in Ruby, a comment on the first line that contains `coding:` names the file's encoding.
          hint = ["`coding:` in a comment on the first line names the file's encoding, as in Ruby; reword the comment or move it to a later line"] if e.message.include?("magic comment")
          diags << Diagnostic.new(file, e.location.start_line, e.location.start_column, "syntax error: #{e.message}", hint)
        end
        next
      end
      root = result.value
      sources[root.location.send(:source)] = file
      root.statements.body.each do |st|
        if Resolver.generate_call?(st)
          generate_stage0(st, file, dir, generator, generated, seen, diags) { |name, text, gdir| visit.(name, text, gdir) }
          next
        end
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
        target = dir == "." || File.absolute_path?(name) ? name : File.join(dir, name)
        if name.match?(/[*?\[{]/)
          # `require "sql/*"`: every matching .sake file next to the requiring file, in name order (the
          # requiring file itself excepted). Definitions are collected before anything runs, so the order
          # only matters for top-level statements.
          matches = Dir.glob(target).sort.reject { File.expand_path(_1) == File.expand_path(file) || File.directory?(_1) }
          if matches.empty?
            diags << Diagnostic.new(file, loc.start_line, loc.start_column, "require: nothing matches #{target}", [])
            next
          end
          matches.each do |m|
            next if seen[File.expand_path(m)]
            seen[File.expand_path(m)] = true
            visit.(m, File.read(m))
          end
          next
        end
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
    # The prelude (sakelib/prelude.sake: Enum) comes first, as if every program began with `require "prelude"`.
    unless seen[File.expand_path(PRELUDE)]
      seen[File.expand_path(PRELUDE)] = true
      visit.(PRELUDE, File.read(PRELUDE))
    end
    visit.(path, source)
    raise StaticErrors.new(diags) unless diags.empty?
    registry = Registry.new
    Stdlib.install(registry, out)
    Stdlib.install_ext(registry, out, input)
    Resolver.new(path, files, registry, sources).resolve
  end

  # One `generate` statement: runs its generator and hands the source it printed to visit (name, source, dir).
  def generate_stage0(st, file, dir, generator, generated, seen, diags)
    loc = st.location
    args = st.arguments&.arguments || []
    unless !args.empty? && args.all?(Prism::StringNode) && st.block.nil?
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate takes string literals, as in `generate \"gen\", \"arg\"`",
                              ["the generator and its arguments (its ARGV) are decided before running"])
      return
    end
    name, *argv = args.map(&:unescaped)
    name += ".sake" if File.extname(name).empty?
    target = dir == "." || File.absolute_path?(name) ? name : File.join(dir, name)
    target = File.join(SAKELIB, name) if !File.exist?(target) && File.exist?(File.join(SAKELIB, name))
    site = "(generate at #{file}:#{loc.start_line})"
    key = [:generate, File.expand_path(target), argv]
    return if seen[key]
    seen[key] = true
    unless File.exist?(target)
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate: cannot read #{target}", [])
      return
    end
    active = (Thread.current[:sake_generating] ||= [])
    if active.include?(File.expand_path(target))
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate: #{target} is already generating (a cycle)", [])
      return
    end
    begin
      active << File.expand_path(target)
      text = generator.(target, argv)
    rescue StaticErrors => e
      diags.concat(e.diagnostics)
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate: the generator #{target} has the problems above", [])
      return
    rescue SystemCallError => e # a directory, or no permission
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate: cannot read #{target} (#{e.message.sub(/ @ .*/, "")})", [])
      return
    rescue RunError => e
      e.path ||= target
      diags << Diagnostic.new(file, loc.start_line, loc.start_column, "generate: the generator #{target} failed:\n  #{e.report.gsub("\n", "\n  ")}", [])
      return
    ensure
      active.pop
    end
    generated&.push([site, target, argv, text])
    Sake.origins[site] = origin_map(text)
    yield site, text, dir
  end

  # `# sake-origin: FILE:LINE` in generated source: the lines after it, up to the next marker, came from FILE:LINE
  # (a generator usually writes several lines for one line of its input); `# sake-origin: none` ends it.
  # origin_map(text)[n] is [FILE, LINE] for generated line n, or nil.
  def origin_map(text)
    map = [nil]
    at = nil
    text.each_line do |l|
      if (m = l.match(/\A\s*# sake-origin: (?:(.+):(\d+)|none)\s*\z/))
        map << nil
        at = m[1] && [m[1], m[2].to_i]
      else
        map << at
      end
    end
    map
  end

  # Runs a generator program and returns what it printed (stage 0 of `generate`). check: the static check of the
  # generator program beyond resolving (the CLI's --strict level).
  def run_generator(path, argv, check: nil)
    saved = [Sake.program_name, Sake.argv]
    buf = StringIO.new
    Sake.argv = argv
    program = load(File.read(path), path, out: buf, input: StringIO.new,
                                          generator: ->(p, a) { run_generator(p, a, check:) })
    check&.call(program)
    begin
      execute(program)
    rescue Exit => e
      raise RunError.new("SystemExit", "exit #{e.status}", 0, file: path) unless e.status.zero?
    end
    buf.string
  ensure
    Sake.program_name, Sake.argv = saved
  end

  # Whether a file is a library: its top level holds only definitions (class, module, def, `X = Struct.new`)
  # and requires. A file that also runs something is a program, which a `require` next to it does not mean.
  def library_file?(path)
    result = Prism.parse(File.read(path), filepath: path)
    return true unless result.errors.empty?
    result.value.statements.body.all? do |st|
      case st
      when Prism::ClassNode, Prism::ModuleNode, Prism::DefNode, Prism::ConstantWriteNode then true
      when Prism::CallNode then Resolver.require_call?(st) || Resolver.generate_call?(st)
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
