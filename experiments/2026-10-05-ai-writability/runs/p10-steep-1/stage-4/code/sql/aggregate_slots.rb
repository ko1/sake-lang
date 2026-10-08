# frozen_string_literal: true

require_relative "ast"

module Sql
  # The distinct aggregate calls of one SELECT. A call's value lives at a position of the group's
  # row after the table's width columns; calls written identically share one position.
  class AggregateSlots
    attr_reader :calls

    def initialize(width)
      @width = width
      @calls = [] #: Array[Ast::Aggregate]
      @by_signature = {} #: Hash[String, Ast::Aggregate]
    end

    def empty?
      @calls.empty?
    end

    def width
      @width
    end

    # The Aggregate node for a call, reusing an identical call seen before.
    def add(name, function, args, distinct, star, order_by)
      call = Ast::Aggregate.new(name, function, args, distinct, star, order_by, @width + @calls.length)
      known = @by_signature[call.signature]
      return known if known

      @by_signature[call.signature] = call
      @calls << call
      call
    end
  end
end
