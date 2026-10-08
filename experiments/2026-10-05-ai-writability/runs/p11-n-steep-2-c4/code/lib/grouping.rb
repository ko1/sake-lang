module MiniSql
  # Partitions the rows of a query into groups (SPEC 3.3).
  module Grouping
    # Rows whose GROUP BY values are all equal form a group, in order of first appearance.
    # Without GROUP BY terms all rows form one group, which exists even when there are no rows.
    def self.partition(rows, terms)
      return [rows] if terms.empty?
      partition_indexes(rows, terms).map { |group| group.map { |i| rows.fetch(i) } }
    end

    # The same groups as positions in `rows` (ascending within a group); one group of all rows without terms.
    def self.partition_indexes(rows, terms)
      return [(0...rows.length).to_a] if terms.empty?
      groups = {} # @type var groups: Hash[Array[sql_value], Array[Integer]]
      rows.each_with_index do |row, i|
        key = terms.map { |term| Value.group_key(Evaluator.evaluate(term, row)) }
        group = groups[key]
        if group
          group << i
        else
          groups[key] = [i]
        end
      end
      groups.values
    end
  end
end
