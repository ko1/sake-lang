module MiniSql
  # The window calls of one SELECT and its WINDOW clause (SPEC 6). The calls are computed after WHERE, GROUP BY and
  # HAVING: each row is extended with one value per call, so WindowRef is a position in that extended row.
  class WindowScope
    attr_reader :base

    # named: the windows of the WINDOW clause.
    def initialize(named)
      @named = {} # @type ivar @named: Hash[String, WindowSpec]
      named.each { |window| @named[window.name.downcase(:ascii)] = window.spec }
      @calls = [] # @type ivar @calls: Array[WindowCall]
      @base = 0
    end

    def empty?
      @calls.empty?
    end

    # The reference to the result of `call` (written with `name`).
    def add(call, name)
      @calls << call
      WindowRef.new(self, @calls.length - 1, name)
    end

    # The width of the rows the window values follow; known only when every aggregate has been bound.
    def place(base)
      @base = base
    end

    # The spec with its base window's parts it does not have added (SPEC 6.1); SqlError for an unknown name.
    def resolve(spec, seen = [])
      name = spec.base
      return spec unless name
      key = name.downcase(:ascii)
      base = @named[key]
      raise SqlError, "no such window: #{name}" if base.nil? || seen.include?(key)
      inherited = resolve(base, seen + [key])
      WindowSpec.new(nil, spec.partition_by.empty? ? inherited.partition_by : spec.partition_by,
                     spec.order_by.empty? ? inherited.order_by : spec.order_by, spec.frame || inherited.frame)
    end

    # The rows, each followed by the results of the calls.
    def extended(rows)
      return rows if @calls.empty? || rows.empty?
      results = @calls.map { |call| call.results(rows) }
      rows.each_with_index.map { |row, i| row + results.map { |column| column.fetch(i, nil) } }
    end
  end
end
