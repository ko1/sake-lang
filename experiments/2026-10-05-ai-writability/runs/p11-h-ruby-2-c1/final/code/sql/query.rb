# frozen_string_literal: true

require_relative 'values'

module SQL
  # What every planned query offers its users (SelectQuery, CompoundQuery, RecursiveQuery): the class
  # defines `rows`, `result_names`, `affinities`, `collations` and `correlated?`.
  module Query
    # The lines to print.
    def run = rows.map { |r| r.map { |v| Values.display(v) }.join('|') }

    def width = result_names.size

    # `collations` (one Collation::Info or nil per result column) is defined like `affinities`.

    # `rows` for a source or subquery expression; kept when nothing in it depends on an enclosing row.
    def result_rows
      return rows if correlated?

      @result_rows ||= rows
    end
  end
end
