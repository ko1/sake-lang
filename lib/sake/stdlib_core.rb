# frozen_string_literal: true

module Sake
  # The rest of Ruby's core API that the table (stdlib_table.rb) cannot express: results that depend on the
  # arguments' count or kinds, in-place forms that must keep a typed Array's or a Set's invariants, and a few
  # values read as operations (2026-10-09, experiments/2026-10-09-stdlib-port).
  module Stdlib
    module_function

    def install_core_more(reg)
      # Array.slice(a, i) / (a, i, n) / (a, range) is a[...]; slice! also removes what it returns.
      %i[slice slice!].each do |m|
        reg.define("Array", m, ["Array", %w[Integer Range]], optional: ["Integer"]) do |a, i, n = nil|
          ruby_error("TypeError") { n ? a.public_send(m, i, n) : a.public_send(m, i) }
        end
      end
      reg.define("Array", :prepend, ["Array"], rest: "Any") { |a, *xs| a.unshift(*check_elems(a, xs)) }
      # assoc / rassoc: the first element (a Tuple or an Array) whose first / second item equals the key.
      # Ruby's look for Arrays only; Sake's pairs are Tuples.
      reg.define("Array", :assoc, %w[Array Any]) { |a, k| a.find { |e| (row = row_items(e)) && row[0] == k } }
      reg.define("Array", :rassoc, %w[Array Any]) { |a, v| a.find { |e| (row = row_items(e)) && row[1] == v } }
      # map! / collect!: each element replaced by the block's value (a typed Array keeps its element type).
      %i[map! collect!].each do |m|
        reg.define("Array", m, ["Array"], block: :required) { |a, &b| a.map! { |x| check_elems(a, [b.(x)])[0] } }
      end
      reg.define("Set", :map!, ["Set"], block: :required) { |s, &b| s.map! { |x| key!(b.(x)) } }
      reg.define("Set", :collect!, ["Set"], block: :required) { |s, &b| s.map! { |x| key!(b.(x)) } }
      reg.define("Hash", :transform_keys!, ["Hash"], block: :required) { |h, &b| h.transform_keys! { |k| key!(b.(k)) } }
      # Hash.set_default(h, v): the value a missing key gives from now on (Ruby's h.default = v).
      reg.define("Hash", :set_default, %w[Hash Any]) { |h, v| h.default = v }
      # String.sub!(s, pat, repl) / gsub!: in place; nil when nothing matched (Ruby). As sub/gsub, the
      # replacement is a String, a Hash, or a block.
      %i[sub! gsub!].each do |m|
        reg.define("String", m, ["String", %w[String Regexp]], optional: [%w[String Hash]], block: :optional) do |s, pat, repl = nil, &b|
          ruby_error("TypeError") do
            if repl.is_a?(Hash) then s.send(m, pat, repl.transform_values { Values.to_s(_1) })
            elsif repl then s.send(m, pat, repl)
            elsif b then s.send(m, pat) { Values.to_s(b.call(Regexp.last_match[0])) }
            else raise Fail.new("ArgumentError", "#{m} needs a replacement or a block")
            end
          end
        end
      end
      # String.slice!(s, i) / (s, i, n) / (s, range) / (s, str) / (s, regexp): removes and gives the part, or nil.
      reg.define("String", :slice!, ["String", %w[Integer Range String Regexp]], optional: ["Integer"]) do |s, i, n = nil|
        ruby_error("TypeError") { n ? s.slice!(i, n) : s.slice!(i) }
      end
      # Child processes (Ruby's open3 is built in: a program cannot spawn one otherwise). Kernel.system(cmd, *args)
      # runs a command (true, false, or nil when it could not start, as Ruby); Open3.capture2 / capture2e / capture3
      # give the output(s) and the exit status as a Tuple ([out, status], [out, err, status]).
      reg.define("Kernel", :system, ["String"], rest: "String") { |cmd, *args| system(cmd, *args) }
      reg.define("Open3", :capture2, ["String"], rest: "String") do |cmd, *args|
        require "open3"
        io_error { Open3.capture2(cmd, *args).then { |out, st| Tuple.new([out, st.exitstatus || -1]) } }
      end
      reg.define("Open3", :capture2e, ["String"], rest: "String") do |cmd, *args|
        require "open3"
        io_error { Open3.capture2e(cmd, *args).then { |out, st| Tuple.new([out, st.exitstatus || -1]) } }
      end
      reg.define("Open3", :capture3, ["String"], rest: "String") do |cmd, *args|
        require "open3"
        io_error { Open3.capture3(cmd, *args).then { |out, err, st| Tuple.new([out, err, st.exitstatus || -1]) } }
      end
      # Zlib: Ruby's compression, which a library in Sake cannot match in speed.
      %i[inflate deflate gzip gunzip].each do |m|
        reg.define("Zlib", m, ["String"]) do |s|
          require "zlib"
          begin
            ::Zlib.public_send(m, s)
          rescue ::Zlib::Error => e
            raise Fail.new("ArgumentError", e.message)
          end
        end
      end
      # Record.to_h(r) / keys / values: a Record's fields as data (Symbol keys), for code that walks any Record.
      reg.define("Record", :to_h, ["Any"]) { |r| record!(r).shape.fields.zip(r.values).to_h { |f, v| [f.to_sym, v] } }
      reg.define("Record", :keys, ["Any"]) { |r| record!(r).shape.fields.map(&:to_sym) }
      reg.define("Record", :values, ["Any"]) { |r| record!(r).values.dup }
      # at_exit { ... }: the block runs when the program ends (normally, by exit, or by an error), last registered
      # first, as Ruby's. The block is kept by the interpreter, as Thread.new keeps its block.
      reg.define("Kernel", :at_exit, [], block: :required) do |&b|
        Sake.at_exit_blocks << b
        nil
      end
      # Kernel.PROGRAM_NAME: the program's path (Ruby's $0). Kernel.equal?(a, b): the same value, not just equal.
      reg.define("Kernel", :PROGRAM_NAME, []) { Sake.program_name || $0 }
      reg.define("Kernel", :equal?, %w[Any Any]) { |a, b| a.equal?(b) }
      # Process.clock_gettime(Process.CLOCK_MONOTONIC): the clocks are read as operations, as Math.PI is.
      { CLOCK_REALTIME: Process::CLOCK_REALTIME, CLOCK_MONOTONIC: Process::CLOCK_MONOTONIC,
        CLOCK_PROCESS_CPUTIME_ID: Process::CLOCK_PROCESS_CPUTIME_ID }.each do |name, v|
        reg.define("Process", name, []) { v }
      end
    end

    def record!(r)
      raise Fail.new("TypeError", "argument 1 must be a Record, got #{Values.describe(r)}") unless r.is_a?(RecordValue)
      r
    end

    def row_items(e)
      case e
      when Tuple then e.elems
      when Array then e
      end
    end

    # The frozen Strings a program meets: Hash keys and Set elements (key_copy), ARGV, and Symbol names.
    def frozen_error
      yield
    rescue ::FrozenError
      raise Fail.new("TypeError", "cannot change this String in place: it is a Hash key, a Set element, or a program argument")
    end
  end
end
