# frozen_string_literal: true

require_relative "../sake"

module Sake
  module CLI
    USAGE = <<~TEXT
      usage: sake [--check] FILE.sake

        --check   only run the static checks (name resolution, arity, syntax)

      exit status: 0 = ok, 1 = runtime error, 2 = static error (reported before running)
    TEXT

    module_function

    def main(argv, out: $stdout, err: $stderr)
      check_only = !argv.delete("--check").nil?
      if argv.size != 1 || argv.first.start_with?("-")
        err.write(USAGE)
        return argv.include?("--help") || argv.include?("-h") ? 0 : 2
      end
      path = argv.first
      source = File.read(path)
      if check_only
        Sake.load(source, path, out:)
      else
        Sake.run(source, path, out:)
      end
      0
    rescue StaticErrors => e
      out.flush
      err.puts e.message
      2
    rescue RunError => e
      out.flush
      err.puts e.report
      1
    end
  end
end
