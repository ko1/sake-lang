# frozen_string_literal: true

require_relative "../sake"

module Sake
  module CLI
    USAGE = <<~TEXT
      usage: sake [--check | --types] FILE.sake

        --check   only run the static checks (name resolution, arity, syntax)
        --types   experimental: infer types and classify each runtime type check as
                  proven / partial (union) / error (surely fails) / unknown

      exit status: 0 = ok, 1 = runtime error, 2 = static error (reported before running)
    TEXT

    module_function

    def main(argv, out: $stdout, err: $stderr)
      check_only = !argv.delete("--check").nil?
      types = !argv.delete("--types").nil?
      if argv.size != 1 || argv.first.start_with?("-")
        err.write(USAGE)
        return argv.include?("--help") || argv.include?("-h") ? 0 : 2
      end
      path = argv.first
      source = File.read(path)
      if types
        require_relative "typer"
        out.write(Typer.new(Sake.load(source, path, out:)).run.report)
      elsif check_only
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
