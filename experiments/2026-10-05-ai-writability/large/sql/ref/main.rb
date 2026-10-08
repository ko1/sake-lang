# Runs a script of SQL statements from standard input against an in-memory database (the reference
# implementation of large/sql/spec, stage 1). Results and errors go to standard output.
require_relative "lexer"
require_relative "parser"
require_relative "database"

def run_script(text, out)
  database = Database.new
  Lexer.split_statements(text).each do |source|
    statement = Parser.parse(source)
    next unless statement
    database.execute(statement).each do |row|
      out.puts(row.map { |value| Values.to_text(value) }.join("|"))
    end
  rescue SqlError => e
    out.puts("Error: #{e.message}")
  end
end

run_script($stdin.read, $stdout)
