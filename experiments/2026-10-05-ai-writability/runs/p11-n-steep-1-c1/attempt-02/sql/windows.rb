# frozen_string_literal: true

require_relative "ast"
require_relative "evaluator"
require_relative "value"
require_relative "window_functions"
require_relative "window_partition"

module Sql
  # Window calls (spec 6): fills in the value of each call in every row, before DISTINCT,
  # ORDER BY and LIMIT.
  module Windows
    # rows each have a slot for every call (calls' index); they are changed in place.
    def self.apply(calls, rows)
      calls.each { |call| fill(call, rows) }
    end

    def self.fill(call, rows)
      partitions(call, rows).each do |members|
        partition = WindowPartition.new(call, members)
        (0...partition.size).each { |pos| partition.row(pos)[call.index] = WindowFunctions.value(call, partition, pos) }
      end
    end

    # The rows split by the call's PARTITION BY values (NULLs equal, TEXT equal under the term's
    # collation); one group without it.
    def self.partitions(call, rows)
      buckets = {} #: Hash[Array[value], Array[Array[value]]]
      terms = call.partition_by
      collations = terms.map(&:collation_or_binary)
      rows.each do |row|
        key = terms.each_with_index.map { |expr, i| Value.identity(Value.fold(Evaluator.evaluate(expr, row), collations.fetch(i))) }
        bucket = buckets[key]
        if bucket
          bucket << row
        else
          buckets[key] = [row]
        end
      end
      buckets.values
    end
  end
end
