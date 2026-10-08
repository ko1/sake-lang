# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'

module SQL
  # Collating sequences (SPEC 7): how two TEXT values compare. A collation name is :binary, :nocase or
  # :rtrim; `nil` stands for BINARY wherever a name is taken (the comparison itself is in Values).
  #
  # What an expression carries is an Info (or nil for "none"): the name and whether it is explicit
  # (`e COLLATE n`) or implicit (a column's, 7.3).
  module Collation
    NAMES = { 'BINARY' => :binary, 'NOCASE' => :nocase, 'RTRIM' => :rtrim }.freeze

    Info = Data.define(:name, :explicit)

    module_function

    # The name for a collation as written (case-insensitive); the error of 7.7 for an unknown one.
    def lookup(written)
      NAMES.fetch(written.upcase) { raise SqlError, "no such collation sequence: #{written}" }
    end

    def implicit(name) = Info.new(name, false)

    def explicit(name) = Info.new(name, true)

    def name_of(info) = info&.name

    # The collation of `a op b` (7.4): an explicit one (a's first), else an implicit one (a's first), else none.
    def choose(a, b)
      return a if a&.explicit
      return b if b&.explicit

      a || b
    end

    # `expr [COLLATE n]` of a term that may name a result column: [expr without COLLATE, name as written or nil].
    def split_term(expr) = expr.is_a?(Collate) ? [expr.expr, expr.name] : [expr, nil]

    # The collation of each column of a compound: the first part's that has one (7.4).
    # `lists` is one array of Info-or-nil per simple select, left to right.
    def merge(lists)
      lists.first.each_index.map { |k| lists.filter_map { |l| l[k] }.first }
    end
  end
end
