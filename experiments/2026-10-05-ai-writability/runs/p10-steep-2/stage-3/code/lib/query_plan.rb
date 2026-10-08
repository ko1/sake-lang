module MiniSql
  # A SELECT after name resolution: everything Query needs to read rows and build the output.
  class QueryPlan
    attr_reader :table, :results, :where, :group_by, :having, :aggregates, :distinct, :keys, :limit, :offset

    # aggregates is the AggregateScope of an aggregate query (SPEC 3.3) and nil for other queries;
    # group_by is empty without GROUP BY terms; limit is nil for no limit.
    def initialize(table, results, where, group_by, having, aggregates, distinct, keys, limit, offset)
      @table = table
      @results = results
      @where = where
      @group_by = group_by
      @having = having
      @aggregates = aggregates
      @distinct = distinct
      @keys = keys
      @limit = limit
      @offset = offset
    end
  end
end
