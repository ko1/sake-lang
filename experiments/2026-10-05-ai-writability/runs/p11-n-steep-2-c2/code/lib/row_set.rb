module MiniSql
  # Rows compared as SELECT DISTINCT does (SPEC 3.4): pairwise equal by 1.9, NULLs equal to each other.
  module RowSet
    # A value that is equal for rows that are equal in this sense.
    def self.key(row)
      row.map { |value| Value.group_key(value) }
    end

    # One of each set of equal rows, the first, in order.
    def self.distinct(rows)
      seen = {} # @type var seen: Hash[Array[sql_value], bool]
      rows.select do |row|
        signature = key(row)
        seen[signature] ? false : (seen[signature] = true)
      end
    end

    # The set of rows as a lookup table of keys.
    def self.keys_of(rows)
      keys = {} # @type var keys: Hash[Array[sql_value], bool]
      rows.each { |row| keys[key(row)] = true }
      keys
    end
  end
end
