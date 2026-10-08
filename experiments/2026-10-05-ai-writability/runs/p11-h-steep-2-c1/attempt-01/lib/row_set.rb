module MiniSql
  # Rows compared as SELECT DISTINCT does (SPEC 3.4): pairwise equal by 1.9, NULLs equal to each other, TEXT
  # values equal under the collation of their column (SPEC 7.4); collations has one per column.
  module RowSet
    # A value that is equal for rows that are equal in this sense.
    def self.key(row, collations)
      row.each_with_index.map { |value, i| Collation.key(collations.fetch(i, :binary), value) }
    end

    # One of each set of equal rows, the first, in order.
    def self.distinct(rows, collations)
      seen = {} # @type var seen: Hash[Array[sql_value], bool]
      rows.select do |row|
        signature = key(row, collations)
        seen[signature] ? false : (seen[signature] = true)
      end
    end

    # The set of rows as a lookup table of keys.
    def self.keys_of(rows, collations)
      keys = {} # @type var keys: Hash[Array[sql_value], bool]
      rows.each { |row| keys[key(row, collations)] = true }
      keys
    end
  end
end
