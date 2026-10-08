# frozen_string_literal: true

require_relative "ast"
require_relative "window_defs"

module Sql
  # The aggregate calls and window calls of one SELECT. A call's value lives at a position of the
  # row after the table's width columns, in the order the calls were added; aggregate calls
  # written identically share one position. windows are the SELECT's named windows.
  class CallSlots
    attr_reader :all, :aggregates, :windows, :window_defs

    def initialize(width, window_defs)
      @width = width
      @window_defs = window_defs
      @all = [] #: Array[Ast::SlotExpr]
      @aggregates = [] #: Array[Ast::Aggregate]
      @windows = [] #: Array[Ast::WindowCall]
      @by_signature = {} #: Hash[String, Ast::Aggregate]
    end

    def width
      @width
    end

    # The Aggregate node for a call, reusing an identical call seen before.
    def add_aggregate(name, function, args, distinct, star, order_by)
      call = Ast::Aggregate.new(name, function, args, distinct, star, order_by, @width + @all.length)
      known = @by_signature[call.signature]
      return known if known

      @by_signature[call.signature] = call
      @all << call
      @aggregates << call
      call
    end

    # The WindowCall node for a window function call (each call has its own).
    def add_window(name, function, args, spec, frame, aggregate)
      call = Ast::WindowCall.new(name, function, args, spec.partition_by, spec.order_by, frame, aggregate, @width + @all.length)
      @all << call
      @windows << call
      call
    end
  end
end
