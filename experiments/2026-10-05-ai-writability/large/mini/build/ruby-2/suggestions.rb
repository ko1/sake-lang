module Mini
  # "did you mean ...?" for undefined names (section 5.2).
  module Suggestions
    module_function

    # `scopes` lists the visible names of each scope, innermost first. The
    # closest name within the allowed distance wins; ties go to the innermost
    # scope, then to the alphabetically first name. Returns nil when none fits.
    def suggest(name, scopes)
      limit = [2, (name.length - 1) / 2].min
      best = nil
      best_distance = nil
      scopes.each do |names|
        names.sort.each do |candidate|
          distance = edit_distance(name, candidate)
          next if distance > limit
          next if best_distance && distance >= best_distance
          best = candidate
          best_distance = distance
        end
      end
      best
    end

    # Insertions, deletions, substitutions and swaps of two adjacent
    # characters, each counting 1 (optimal string alignment distance).
    def edit_distance(a, b)
      rows = Array.new(a.length + 1) { |i| Array.new(b.length + 1) { |j| i.zero? ? j : (j.zero? ? i : 0) } }
      (1..a.length).each do |i|
        (1..b.length).each do |j|
          cost = a[i - 1] == b[j - 1] ? 0 : 1
          d = [rows[i - 1][j] + 1, rows[i][j - 1] + 1, rows[i - 1][j - 1] + cost].min
          if i > 1 && j > 1 && a[i - 1] == b[j - 2] && a[i - 2] == b[j - 1]
            d = [d, rows[i - 2][j - 2] + 1].min
          end
          rows[i][j] = d
        end
      end
      rows[a.length][b.length]
    end
  end
end
