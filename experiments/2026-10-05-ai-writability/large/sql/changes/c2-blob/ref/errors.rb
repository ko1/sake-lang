# An error a statement reports as "Error: <message>"; the statement then has no effect.
class SqlError < StandardError
  def self.syntax
    new("syntax error")
  end
end
