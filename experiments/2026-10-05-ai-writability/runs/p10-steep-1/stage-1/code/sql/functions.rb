# frozen_string_literal: true

require_relative "schema"
require_relative "value"

module Sql
  # Scalar functions. Names are lower case; a max of nil means any number of arguments.
  module Functions
    class Spec
      attr_reader :min, :max

      def initialize(min, max)
        @min = min
        @max = max
      end

      def accepts?(count)
        max = @max
        count >= @min && (max.nil? || count <= max)
      end
    end

    SPECS = {
      "length" => Spec.new(1, 1),
      "upper" => Spec.new(1, 1),
      "lower" => Spec.new(1, 1),
      "abs" => Spec.new(1, 1),
      "typeof" => Spec.new(1, 1),
      "coalesce" => Spec.new(2, nil),
      "ifnull" => Spec.new(2, 2),
      "nullif" => Spec.new(2, 2)
    }.freeze

    def self.lookup(name)
      SPECS[Names.fold(name)]
    end

    # Calls a function whose name and argument count were already checked by lookup.
    def self.call(name, args)
      first = args.fetch(0)
      case Names.fold(name)
      when "typeof" then Value.type_name(first)
      when "coalesce", "ifnull" then args.find { |arg| !arg.nil? }
      when "nullif" then Value.compare(first, args.fetch(1)) == 0 ? nil : first
      else
        return nil if first.nil?

        unary(Names.fold(name), first)
      end
    end

    # The functions of one non-NULL argument that return NULL for NULL.
    def self.unary(name, arg)
      case name
      when "length" then Value.text_form(arg).length
      when "upper" then Value.text_form(arg).tr("a-z", "A-Z")
      when "lower" then Value.text_form(arg).tr("A-Z", "a-z")
      else absolute(arg)
      end
    end

    def self.absolute(arg)
      case arg
      when Integer then arg.abs
      when Float then arg.abs
      else Value.to_number(arg).to_f.abs
      end
    end
  end
end
