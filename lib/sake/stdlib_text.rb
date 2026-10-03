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
    end
  end
end
