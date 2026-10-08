# frozen_string_literal: true

require_relative "ast"
require_relative "error"
require_relative "schema"

module Sql
  # The named windows of one SELECT (its WINDOW clause), and the checks of a window (spec 6.1, 6.2).
  class WindowDefs
    def initialize(named)
      @by_name = {} #: Hash[String, Ast::WindowSpec]
      named.each { |window| @by_name[Names.fold(window.name)] = window.spec }
    end

    # The window a spec stands for, with the parts of the named window it extends filled in.
    # Raises if the window is unknown or its frame is not allowed.
    def bind(spec)
      bound = expand(spec, [])
      check_frame(bound)
      bound
    end

    private

    def expand(spec, seen)
      base_name = spec.base_name
      return spec unless base_name

      key = Names.fold(base_name)
      base = @by_name[key]
      raise Error, "no such window: #{base_name}" if base.nil? || seen.include?(key)

      base = expand(base, seen + [key])
      Ast::WindowSpec.new(nil, spec.partition_by.empty? ? base.partition_by : spec.partition_by,
                          spec.order_by.empty? ? base.order_by : spec.order_by, spec.frame || base.frame)
    end

    def check_frame(spec)
      frame = spec.frame
      return unless frame

      first = frame.first
      last = frame.last
      unsupported = (first.kind == :current && last.kind == :preceding) ||
                    (first.kind == :following && (last.kind == :preceding || last.kind == :current))
      raise Error, "unsupported frame specification" if unsupported

      with_offset = !first.offset.nil? || !last.offset.nil?
      if !frame.rows? && with_offset && spec.order_by.length != 1
        raise Error, "RANGE with offset PRECEDING/FOLLOWING requires one ORDER BY expression"
      end

      check_offset(frame, first, "starting")
      check_offset(frame, last, "ending")
    end

    def check_offset(frame, bound, which)
      offset = bound.offset
      return unless offset

      invalid = offset < 0 || (frame.rows? && offset.is_a?(Float))
      raise Error, "frame #{which} offset must be a non-negative #{frame.rows? ? "integer" : "number"}" if invalid
    end
  end
end
