module MiniSql
  # A user-visible SQL error: the message is printed as `Error: <message>`.
  class SqlError < StandardError
  end
end
