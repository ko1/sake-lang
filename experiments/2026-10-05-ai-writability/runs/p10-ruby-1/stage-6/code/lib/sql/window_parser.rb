# frozen_string_literal: true

require_relative "ast"
require_relative "errors"

module Sql
  # Parsing of window functions (6.1): OVER, window specs, frames, the WINDOW clause. Mixed into Parser.
  module WindowParser
    private

    # The call with its `OVER name` / `OVER (spec)` if one follows.
    def with_over(call)
      return call unless accept_kw("OVER")
      call.with(over: op?("(") ? parse_window_spec : expect_ident)
    end

    # WINDOW name AS (spec) [, ...]
    def parse_window_definitions
      defs = [parse_window_definition]
      defs << parse_window_definition while accept_op(",")
      defs
    end

    def parse_window_definition
      name = expect_ident
      expect_kw("AS")
      WindowDef.new(name, parse_window_spec)
    end

    # ( [base] [PARTITION BY exprs] [ORDER BY terms] [frame] )
    def parse_window_spec
      expect_op("(")
      base = peek.type == :ident ? advance.value : nil
      partition_by = []
      if accept_kw("PARTITION")
        expect_kw("BY")
        partition_by = parse_expression_list
      end
      order_by = accept_order_by_clause
      frame = kw?("ROWS") || kw?("RANGE") ? parse_frame : nil
      expect_op(")")
      WindowSpec.new(base, partition_by, order_by, frame)
    end

    # (ROWS | RANGE) bound | (ROWS | RANGE) BETWEEN bound AND bound
    def parse_frame
      units = advance.value == "ROWS" ? :rows : :range
      return Frame.new(units, parse_frame_bound, FrameBound.new(:current, nil)) unless accept_kw("BETWEEN")
      start = parse_frame_bound
      expect_kw("AND")
      Frame.new(units, start, parse_frame_bound)
    end

    def parse_frame_bound
      if accept_kw("UNBOUNDED")
        return FrameBound.new(accept_kw("PRECEDING") ? :unbounded_preceding : (expect_kw("FOLLOWING") && :unbounded_following), nil)
      end
      if accept_kw("CURRENT")
        expect_kw("ROW")
        return FrameBound.new(:current, nil)
      end
      negative = !accept_op("-").nil?
      t = advance
      fail_syntax unless t.type == :int || t.type == :float
      offset = negative ? -t.value : t.value
      FrameBound.new(accept_kw("PRECEDING") ? :preceding : (expect_kw("FOLLOWING") && :following), offset)
    end
  end
end
