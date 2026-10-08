module MiniSql
  # Runs a whole script: one statement at a time, printing results and `Error: ...` lines.
  class Interpreter
    def initialize(out)
      @out = out
      @executor = Executor.new(Database.new)
    end

    def run(source)
      Lexer.statements(source).each do |tokens|
        lines = begin
          @executor.execute(Parser.parse(tokens))
        rescue SqlError => e
          ["Error: #{e.message}"]
        end
        lines.each { |line| @out.puts(line) }
      end
    end
  end
end
