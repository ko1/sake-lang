module MiniSql
  # A SELECT after name resolution: everything Query needs to read rows and build the output.
  class QueryPlan
    attr_reader :from, :results, :columns, :where, :group_by, :having, :aggregates, :distinct, :keys, :limit, :offset

    # from is the FROM clause; columns describes the result columns (name and affinity) for a query that
    # is a subquery. aggregates is the AggregateScope of an aggregate query (SPEC 3.3) and nil for other queries;
    # group_by is empty without GROUP BY terms; limit is nil for no limit.
    def initialize(from, results, columns, where, group_by, having, aggregates, distinct, keys, limit, offset)
      @from = from
      @results = results
      @columns = columns
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
