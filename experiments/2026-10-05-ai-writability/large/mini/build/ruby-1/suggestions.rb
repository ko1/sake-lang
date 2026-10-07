# frozen_string_literal: true

module Mini
  # "did you mean" for undefined names (SPEC section 5.2).
  module Suggestions
    module_function

    # The candidate to suggest for `name`, or nil. `scopes` lists the visible
    # names scope by scope, innermost first.
    def suggest(name, scopes)
      limit = [2, (name.length - 1) / 2].min
      best = nil
      best_distance = nil
      scopes.each do |names|
        names.sort.each do |candidate|
          d = distance(name, candidate)
          next if d > limit || (best_distance && d >= best_distance)

          best = candidate
          best_distance = d
        end
      end
      best
    end

    # Edit distance counting insertions, deletions, substitutions and swaps
    # of two adjacent characters (optimal string alignment).
    def distance(a, b)
      a = a.chars
      b = b.chars
      d = Array.new(a.size + 1) { |i| Array.new(b.size + 1) { |j| i.zero? ? j : (j.zero? ? i : 0) } }
      (1..a.size).each do |i|
        (1..b.size).each do |j|
          cost = a[i - 1] == b[j - 1] ? 0 : 1
          d[i][j] = [d[i - 1][j] + 1, d[i][j - 1] + 1, d[i - 1][j - 1] + cost].min
          if i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]
            d[i][j] = [d[i][j], d[i - 2][j - 2] + 1].min
          end
        end
      end
      d[a.size][b.size]
    end
  end
end
