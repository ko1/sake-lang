# frozen_string_literal: true

require_relative "error"

module Sql
  # Collations (spec 7): how two TEXT values compare. A collation is :binary, :nocase or :rtrim.
  module Collation
    # The collation called name (any case), or the error for an unknown name.
    def self.fetch(name)
      case name.tr("A-Z", "a-z")
      when "binary" then :binary
      when "nocase" then :nocase
      when "rtrim" then :rtrim
      else raise Error, "no such collation sequence: #{name}"
      end
    end

    # The text as the collation compares it: two texts are equal under it exactly when their folds are
    # equal, and their order is the byte order of their folds.
    def self.fold(text, collation)
      case collation
      when :nocase then text.tr("A-Z", "a-z")
      when :rtrim then text.sub(/ +\z/, "")
      else text
      end
    end

    # The collation of a comparison of a and b (spec 7.4): an explicit one (a's first), else an
    # implicit one (a's first), else BINARY.
    def self.choose(left, left_explicit, right, right_explicit)
      if left_explicit then left || :binary
      elsif right_explicit then right || :binary
      else left || right || :binary
      end
    end

    # BINARY for the columns that have no collation.
    def self.defaulted(list)
      out = [] #: Array[collation]
      list.each { |collation| out << (collation || :binary) }
      out
    end

    # The collation of each of count columns of a compound select (spec 7.4): that of the first part
    # (lists has the parts' result_collations) whose column has one, else BINARY.
    def self.merge(lists, count)
      merged = [] #: Array[collation]
      (0...count).each do |k|
        found = nil #: collation?
        lists.each { |list| found ||= list.fetch(k) }
        merged << (found || :binary)
      end
      merged
    end
  end
end
