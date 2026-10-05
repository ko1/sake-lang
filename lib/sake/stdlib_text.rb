# frozen_string_literal: true

module Sake
  # A program's command-line arguments (ARGV) and `exit`, set and caught by the CLI.
  class << self
    def argv = @argv ||= []

    def argv=(xs)
      @argv = xs.map { _1.dup.freeze }
    end
  end

  # Raised by Kernel.exit: ends the program with status (ensure clauses run on the way out).
  class Exit < StandardError
    attr_reader :status

    def initialize(status)
      @status = status
      super("exit #{status}")
    end
  end

  module Stdlib
    module_function

    # Positions, bytes, block replacement, and the program's arguments: what the ports of Ruby's
    # library asked for most (experiments/2026-10-03-sakelib-port/builtin-requests.md).
    def install_text(reg, out)
      str_re = %w[String Regexp]
      reg.define("String", :index, ["String", str_re], optional: ["Integer"]) { |s, t, pos = 0| s.index(t, pos) }
      reg.define("String", :rindex, ["String", str_re], optional: ["Integer"]) { |s, t, pos = s.size| s.rindex(t, pos) }
      reg.define("String", :byteindex, ["String", str_re], optional: ["Integer"]) do |s, t, pos = 0|
        ruby_error("IndexError") { s.byteindex(t, pos) }
      end
      reg.define("String", :byteslice, %w[String Integer], optional: ["Integer"]) { |s, i, n = nil| n ? s.byteslice(i, n) : s.byteslice(i) }
      reg.define("String", :b, ["String"], &:b)
      reg.define("String", :unpack, %w[String String]) { |s, fmt| ruby_error("ArgumentError") { s.unpack(fmt) } }
      reg.define("String", :unpack1, %w[String String]) { |s, fmt| ruby_error("ArgumentError") { s.unpack1(fmt) } }
      # sub / gsub: a replacement String (with \1 references), a Hash of match => replacement, or a block
      # that gets the match and gives the replacement (shown with to_s).
      %i[sub gsub].each do |m|
        reg.define("String", m, ["String", str_re], optional: [%w[String Hash]], block: :optional) do |s, pat, repl = nil, &b|
          if repl.is_a?(Hash) then s.send(m, pat, repl.transform_values { Values.to_s(_1) })
          elsif repl then s.send(m, pat, repl)
          elsif b then s.send(m, pat) { Values.to_s(b.call(Regexp.last_match[0])) }
          else raise Fail.new("ArgumentError", "#{m} needs a replacement or a block")
          end
        end
      end
      reg.define("Regexp", :match, %w[Regexp String], optional: ["Integer"]) { |r, s, pos = 0| r.match(s, pos) }
      reg.define("Regexp", :match?, %w[Regexp String], optional: ["Integer"]) { |r, s, pos = 0| r.match?(s, pos) }
      reg.define("String", :match, ["String", str_re], optional: ["Integer"]) { |s, r, pos = 0| s.match(r, pos) }
      reg.define("String", :match?, ["String", str_re], optional: ["Integer"]) { |s, r, pos = 0| s.match?(r, pos) }
      reg.define("Kernel", :warn, [], rest: "Any") do |*xs|
        xs.flat_map { Values.puts_lines(_1) }.each { $stderr.puts(_1) }
        out.flush if out.respond_to?(:flush)
        nil
      end
      reg.define("Kernel", :exit, [], optional: [%w[Integer Boolean]]) do |st = 0|
        raise Exit.new(st == true ? 0 : st == false ? 1 : st)
      end
      reg.define("Kernel", :ARGV, []) { Sake.argv } # one Array for the program: parse! can shorten it, as in Ruby
      reg.define("File", :delete, ["String"]) { |path| io_error { File.delete(path) } }
      # once { ... }: the block's value, computed the first time this place runs and kept for the whole
      # program (the interpreter keys it by the call; see Interpreter#call_builtin).
      reg.define("Kernel", :once, [], block: :required) { |&b| b.call }
      # Arithmetic.round(x) and friends: one operation for any real number, as `x.round` in Ruby
      # (Float.round names a Float); the result's type follows x's (Stdlib table in typer_ext).
      real = %w[Integer Float Rational]
      %i[round floor ceil truncate].each do |m|
        reg.define("Arithmetic", m, [real], optional: ["Integer"]) do |x, n = nil|
          ruby_error("FloatDomainError") { n ? x.public_send(m, n) : x.public_send(m) }
        end
      end
      reg.define("Arithmetic", :abs, [real], &:abs)
      reg.define("Arithmetic", :to_f, [real], &:to_f)
      reg.define("Arithmetic", :to_i, [real]) { |x| ruby_error("FloatDomainError") { x.to_i } }
      reg.define("Arithmetic", :zero?, [real], &:zero?)
      reg.define("Hash", :dup, ["Hash"], &:dup)
      # loop { ... }: until a break (Ruby's loop; StopIteration is not a Sake exception).
      reg.define("Kernel", :loop, [], block: :required) { |&b| loop { b.call } }
      # Math::PI and friends, read as operations (as ARGV is): Sake has no value constants.
      { "Math" => { PI: Math::PI, E: Math::E },
        "Float" => { INFINITY: Float::INFINITY, NAN: Float::NAN, EPSILON: Float::EPSILON, MAX: Float::MAX, MIN: Float::MIN } }.each do |ns, cs|
        cs.each { |name, v| reg.define(ns, name, []) { v } }
      end
      # block_given?: lowered to AST::BlockGiven, as it reads the calling function's frame.
      reg.define("Kernel", :block_given?, []) { raise "BUG: block_given? is lowered" }
    end
  end
end
