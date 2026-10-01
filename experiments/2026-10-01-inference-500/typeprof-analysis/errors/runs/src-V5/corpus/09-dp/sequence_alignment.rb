class Scoring
  attr_reader :match, :mismatch, :gap

  def initialize(match, mismatch, gap)
    @match = match
    @mismatch = mismatch
    @gap = gap
  end
end

class Alignment
  attr_reader :score, :top, :bottom, :start

  def initialize(score, top, bottom, start)
    @score = score
    @top = top
    @bottom = bottom
    @start = start
  end

  def identity
    same = (0...@top.size).count { |i| @top[i] == @bottom[i] && @top[i] != "-" }
    @top.empty? ? 0.0 : 100.0 * same / @top.size
  end

  def marker
    (0...@top.size).map do |i|
      t = @top[i]
      b = @bottom[i]
      t == b ? "|" : (t == "-" || b == "-" ? " " : ".")
    end.join
  end
end

def pair_score(sc, a, b) = a == b ? sc.match : sc.mismatch

# local = true gives Smith-Waterman, otherwise Needleman-Wunsch
def align(s, t, sc, local)
  gap = sc.gap
  n = s.size
  m = t.size
  h = Array.new(n + 1) { |i| Array.new(m + 1) { |j| local ? 0 : (i + j) * gap } }
  move = Array.new(n + 1) { |i| Array.new(m + 1) { |j| i == 0 ? (j == 0 ? :stop : :left) : (j == 0 ? :up : :diag) } }
  move.each { |row| row.fill(:stop) } if local
  best = [0, n, m]
  1.upto(n) do |i|
    1.upto(m) do |j|
      diag = h[i - 1][j - 1] + pair_score(sc, s[i - 1], t[j - 1])
      up = h[i - 1][j] + gap
      left = h[i][j - 1] + gap
      v = diag
      dir = :diag
      if up > v
        v = up
        dir = :up
      end
      if left > v
        v = left
        dir = :left
      end
      if local && v <= 0
        v = 0
        dir = :stop
      end
      h[i][j] = v
      move[i][j] = dir
      best = [v, i, j] if local && v > best[0]
    end
  end
  score, i, j = local ? best : [h[n][m], n, m]
  top = +""
  bottom = +""
  loop do
    case move[i][j]
    when :diag
      top.prepend(s[i - 1])
      bottom.prepend(t[j - 1])
      i -= 1
      j -= 1
    when :up
      top.prepend(s[i - 1])
      bottom.prepend("-")
      i -= 1
    when :left
      top.prepend("-")
      bottom.prepend(t[j - 1])
      j -= 1
    when :stop
      break
    end
  end
  Alignment.new(score, top, bottom, i)
end

def report(title, a)
  puts format("%s: score %d, identity %.1f%%, starts at %d", title, a.score, a.identity, a.start)
  puts "  " + a.top
  puts "  " + a.marker
  puts "  " + a.bottom
end

dna = Scoring.new(1, -1, -2)
[["GATTACA", "GCATGCU"], ["AGTACGCA", "TATGC"], ["ACCGTTGACC", "ACGTTGAC"]].each do |s, t|
  report("global #{s}/#{t}", align(s, t, dna, false))
  report("local  #{s}/#{t}", align(s, t, dna, true))
end

protein = Scoring.new(3, -1, -2)
query = "HEAGAWGHEE"
library = ["PAWHEAE", "HEAGAW", "WGHEEPAW", "QQQQ"]
hits = library.map { |seq| [seq, align(query, seq, protein, true)] }
ranked = hits.sort_by { |_, a| -a.score }
puts "library search for #{query}:"
ranked.each do |seq, a|
  puts format("  %-9s score %2d  %s", seq, a.score, a.bottom)
end
