module MiniSql
  # A bound call of a window function or aggregate with OVER (SPEC 6.3). name is lower case; aggregate is the
  # AggregateSpec when the name is an aggregate, which then runs over the frame.
  class WindowCall
    attr_reader :name, :args, :aggregate, :definition

    def initialize(name, args, aggregate, definition)
      @name = name
      @args = args
      @aggregate = aggregate
      @definition = definition
    end

    # The result of the call for each of `rows`, in their order.
    def results(rows)
      @definition.check_offsets
      results = Array.new(rows.length, nil) # @type var results: Array[sql_value]
      Grouping.partition_indexes(rows, @definition.partition_by).each do |indexes|
        partition = partition_of(rows, indexes)
        compute_partition(partition).each_with_index do |value, position|
          results[partition.serial(position)] = value
        end
      end
      results
    end

    private

    def partition_of(rows, indexes)
      order = @definition.order
      candidates = indexes.map do |i|
        row = rows.fetch(i)
        Candidate.new(row, order.map { |key| key.value([], row) }, i)
      end
      WindowPartition.new(order, candidates)
    end

    # The results of the rows of a partition, in partition order. Rows with the same frame share an aggregate.
    def compute_partition(partition)
      spec = @aggregate
      frame = @definition.frame
      known = {} # @type var known: Hash[[Integer, Integer], sql_value]
      Array.new(partition.size) do |position|
        first, last = partition.frame(position, frame)
        if spec
          known[[first, last]] ||= Aggregates.compute(spec, frame_rows(partition, first, last))
        else
          WindowFunctions.compute(@name, @args, partition, position, first, last)
        end
      end
    end

    def frame_rows(partition, first, last)
      (first..last).map { |position| partition.row(position) }
    end
  end
end
