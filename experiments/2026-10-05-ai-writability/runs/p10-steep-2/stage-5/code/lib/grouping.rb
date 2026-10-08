module MiniSql
  # Partitions the rows of a query into groups (SPEC 3.3).
  module Grouping
    # Rows whose GROUP BY values are all equal form a group, in order of first appearance.
    # Without GROUP BY terms all rows form one group, which exists even when there are no rows.
    def self.partition(rows, terms)
      return [rows] if terms.empty?
      groups = {} # @type var groups: Hash[Array[sql_value], Array[Array[sql_value]]]
      rows.each do |row|
        key = terms.map { |term| Value.group_key(Evaluator.evaluate(term, row)) }
        group = groups[key]
        if group
          group << row
        else
          groups[key] = [row]
        end
      end
      groups.values
    end
  end
end
