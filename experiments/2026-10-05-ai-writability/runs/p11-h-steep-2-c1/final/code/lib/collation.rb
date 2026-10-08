module MiniSql
  # Collating sequences (SPEC 7): :binary, :nocase and :rtrim, how two TEXT values compare.
  module Collation
    TRAILING_SPACES = / +\z/

    # The collation called `name` (case-insensitive); :binary for nil (nothing written).
    def self.resolve(name)
      return :binary unless name
      case name.downcase(:ascii)
      when "binary" then :binary
      when "nocase" then :nocase
      when "rtrim" then :rtrim
      else raise SqlError, "no such collation sequence: #{name}"
      end
    end

    # The text as it compares under the collation: texts are equal under it exactly when their folds are equal.
    def self.fold(collation, text)
      case collation
      when :nocase then text.downcase(:ascii)
      when :rtrim then text.sub(TRAILING_SPACES, "")
      else text
      end
    end

    # Order of two texts: -1, 0 or 1.
    def self.compare(collation, left, right)
      (fold(collation, left) <=> fold(collation, right)) || 0
    end

    # The value as a Hash key under equality of 1.9 and the collation (texts equal under it share a key).
    def self.key(collation, value)
      value.is_a?(String) ? fold(collation, value) : Value.group_key(value)
    end

    # The collations of the columns of a compound select (SPEC 7.4): for each column, that of the first of
    # these select column lists (in order) which gives it a collation, else :binary.
    def self.of_compound(lists)
      first = lists.fetch(0)
      first.each_index.map do |k|
        lists.filter_map { |columns| columns[k]&.collation }.first || :binary
      end
    end
  end
end
