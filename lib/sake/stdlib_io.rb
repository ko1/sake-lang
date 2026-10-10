# frozen_string_literal: true

require "tmpdir"
begin
  require "io/console" # absent on ruby.wasm (the playground): IO.winsize/raw/noecho/getch then raise IOError
rescue LoadError
  nil
end

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

    def console(f)
      raise IOError, "not a terminal" unless f.io.respond_to?(:winsize) && f.io.respond_to?(:tty?) && f.io.tty?
      f.io
    end

    def install_streams(reg, out, input)
      stdin = IOValue.new("<STDIN>") { input }
      stdout = IOValue.new("<STDOUT>") { out }
      # stdout is flushed first, so that stdout and stderr lines keep their order (as warn does).
      stderr = IOValue.new("<STDERR>") { (out.flush rescue nil) if out.respond_to?(:flush); $stderr } # stdout may be closed
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
      # read(io): the rest; read(io, n): up to n bytes, nil at the end (Ruby's).
      reg.define("IO", :read, ["IO"], optional: ["Integer"]) { |f, n = nil| io_error { n ? f.io.read(n) : f.io.read } }
      reg.define("IO", :getc, ["IO"]) { |f| io_error { f.io.getc } }
      # Positions, as Ruby's: seek(io, offset[, whence]) with whence 0/1/2 or :SET/:CUR/:END; pos; rewind; truncate.
      reg.define("IO", :seek, %w[IO Integer], optional: [%w[Integer Symbol]]) do |f, off, whence = 0|
        raise Fail.new("ArgumentError", "unknown whence: #{whence.inspect} (0/1/2 or :SET/:CUR/:END)") if whence.is_a?(Symbol) && !%i[SET CUR END].include?(whence)
        io_error { f.io.seek(off, whence.is_a?(Symbol) ? IO.const_get(:"SEEK_#{whence}") : whence) }
      end
      reg.define("IO", :pos, ["IO"]) { |f| io_error { f.io.pos } }
      reg.define("IO", :rewind, ["IO"]) { |f| io_error { f.io.rewind } }
      reg.define("IO", :truncate, %w[IO Integer]) { |f, n| io_error { f.io.truncate(n) } }
      reg.define("IO", :size, ["IO"]) { |f| io_error { f.io.respond_to?(:size) ? f.io.size : raise(IOError, "not a file") } }
      reg.define("IO", :readlines, ["IO"]) { |f| io_error { f.io.readlines } }
      reg.define("IO", :each_line, ["IO"], block: :required) { |f, &b| io_error { f.io.each_line { b.(_1) } } && f }
      reg.define("IO", :eof?, ["IO"]) { |f| io_error { f.io.eof? } }
      reg.define("IO", :flush, ["IO"]) { |f| io_error { f.io.flush } && f }
      reg.define("IO", :close, ["IO"]) { |f| f.io.close.then { nil } }
      reg.define("IO", :closed?, ["IO"]) { |f| f.io.closed? }
      reg.define("IO", :tty?, ["IO"]) { |f| f.io.respond_to?(:tty?) && f.io.tty? }
      # The terminal (io/console): winsize is [rows, columns]; raw / noecho run the block with the terminal in that
      # mode and give its value; getch reads one key. Each is an IOError when the IO is not a terminal.
      reg.define("IO", :winsize, ["IO"]) { |f| io_error { Tuple.new(console(f).winsize) } }
      reg.define("IO", :raw, ["IO"], block: :required) { |f, &b| io_error { console(f).raw { b.call } } }
      reg.define("IO", :noecho, ["IO"], block: :required) { |f, &b| io_error { console(f).noecho { b.call } } }
      reg.define("IO", :getch, ["IO"]) { |f| io_error { console(f).getch } }
      # File.open(path, mode = "r"[, perm]): an IO; with a block, the block's value, the file closed after it.
      reg.define("File", :open, ["String"], optional: %w[String Integer], block: :optional) do |path, mode = "r", perm = nil, &b|
        file = io_error { ruby_error("ArgumentError") { perm ? File.open(path, mode, perm) : File.open(path, mode) } }
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
