# frozen_string_literal: true

require "tmpdir"

module Sake
  # An IO value: the program's stdin/stdout/stderr, or a file from File.open. stdout is the
  # interpreter's output (a StringIO under tests and the IDE); stderr is $stderr when it is used.
  class IOValue
    attr_reader :name

    def initialize(name, &stream)
      @name = name
      @stream = stream
    end

    def io = @stream.call
    def inspect = @name.start_with?("<") ? "#<IO:#{@name}>" : "#<File:#{@name}>"
  end

  module Stdlib
    module_function

    def install_streams(reg, out, input)
      stdin = IOValue.new("<STDIN>") { input }
      stdout = IOValue.new("<STDOUT>") { out }
      # stdout is flushed first, so that stdout and stderr lines keep their order (as warn does).
      stderr = IOValue.new("<STDERR>") { out.flush if out.respond_to?(:flush); $stderr }
      reg.define("IO", :stdin, []) { stdin }
      reg.define("IO", :stdout, []) { stdout }
      reg.define("IO", :stderr, []) { stderr }
      reg.define("IO", :puts, ["IO"], rest: "Any") do |f, *xs|
        lines = xs.empty? ? [""] : xs.flat_map { Values.puts_lines(_1) }
        io_error { lines.each { |l| f.io.write(l.end_with?("\n") ? l : "#{l}\n") } }
        nil
      end
      reg.define("IO", :print, ["IO"], rest: "Any") { |f, *xs| io_error { xs.each { f.io.write(Values.to_s(_1)) } } && nil }
      reg.define("IO", :write, %w[IO String]) { |f, s| io_error { f.io.write(s) } }
      reg.define("IO", :gets, ["IO"]) { |f| io_error { f.io.gets } }
      reg.define("IO", :read, ["IO"]) { |f| io_error { f.io.read } }
      reg.define("IO", :readlines, ["IO"]) { |f| io_error { f.io.readlines } }
      reg.define("IO", :each_line, ["IO"], block: :required) { |f, &b| io_error { f.io.each_line { b.(_1) } } && f }
      reg.define("IO", :eof?, ["IO"]) { |f| io_error { f.io.eof? } }
      reg.define("IO", :flush, ["IO"]) { |f| io_error { f.io.flush } && f }
      reg.define("IO", :close, ["IO"]) { |f| f.io.close.then { nil } }
      reg.define("IO", :closed?, ["IO"]) { |f| f.io.closed? }
      # File.open(path, mode = "r"): an IO; with a block, the block's value, the file closed after it.
      reg.define("File", :open, ["String"], optional: ["String"], block: :optional) do |path, mode = "r", &b|
        file = io_error { ruby_error("ArgumentError") { File.open(path, mode) } }
        f = IOValue.new(path) { file }
        next f unless b
        begin
          b.call(f)
        ensure
          file.close
        end
      end
      # Dir.mktmpdir([prefix, [dir]]): a new directory's path; with a block, the block's value, the
      # directory and everything in it removed after the block (Ruby's tmpdir).
      reg.define("Dir", :mktmpdir, [], optional: %w[String String], block: :optional) do |prefix = nil, dir = nil, &b|
        io_error { b ? Dir.mktmpdir(prefix, dir) { b.(_1) } : Dir.mktmpdir(prefix, dir) }
      end
    end
  end
end
