module MiniSql
  # The aggregate calls of one SELECT. A group is evaluated on a "group row": a row of the group
  # (see #group_row) followed by the aggregate results, so AggregateRef is a position in that row.
  class AggregateScope
    attr_reader :specs

    # width is the number of columns of the table (0 without one).
    def initialize(width)
      @width = width
      @specs = [] # @type var specs: Array[AggregateSpec]
      @refs = {} # @type var refs: Hash[String, AggregateRef]
    end

    def empty?
      @specs.empty?
    end

    # The reference to the result of the aggregate call written `signature`; calls written
    # identically share one computation.
    def ref_for(signature, name, spec)
      known = @refs[signature]
      return known if known
      ref = AggregateRef.new(@width + @specs.length, name)
      @specs << spec
      @refs[signature] = ref
    end

    # The row a group is evaluated on. Columns outside aggregate calls come from one row of the group:
    # with a single min/max aggregate, the row giving the extreme; else the first. An empty group has NULLs.
    def group_row(rows)
      row = bare_row(rows)
      row + @specs.map { |spec| Aggregates.compute(spec, rows) }
    end

    private

    def bare_row(rows)
      only = @specs.length == 1 ? @specs.fetch(0) : nil
      chosen = only ? Aggregates.extreme_row(only, rows) : nil
      chosen || rows.first || Array.new(@width, nil)
    end
  end
end
