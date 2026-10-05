# A live game leaderboard kept sorted with binary-search insertion and removal
# as scores arrive; answers rank, neighbours, and "score needed for top N".

class Entry
  include Comparable
  attr_reader :player, :score

  def initialize(player, score)
    @player = player
    @score = score
  end

  # better entries sort first: higher score, then name
  def <=>(other)
    c = other.score <=> score
    c == 0 ? player <=> other.player : c
  end
end

class Board
  attr_reader :entries, :scores, :moves

  def initialize
    @entries = []
    @scores = {}
    @moves = 0
  end

  def position(e)
    lo = 0
    hi = entries.size
    while lo < hi
      mid = (lo + hi) / 2
      if entries[mid] < e
        lo = mid + 1
      else
        hi = mid
      end
    end
    lo
  end

  def submit(player, points)
    old = scores[player]
    return false if old && old >= points
    entries.delete_at(position(Entry.new(player, old))) if old
    e = Entry.new(player, points)
    i = position(e)
    entries.insert(i, e)
    scores[player] = points
    @moves += entries.size - i
    true
  end

  # competition ranking: ties share the best rank
  def rank(player)
    s = scores[player]
    return nil unless s
    position(Entry.new("", s)) + 1
  end

  def needed_for_top(n)
    return 1 if entries.size < n
    entries[n - 1].score + 1
  end

  def show(n)
    entries.take(n).each do |e|
      puts format("  %2d %-7s %5d", rank(e.player), e.player, e.score)
    end
  end
end

events = [
  ["mika", 1200], ["juno", 950], ["rex", 1430], ["ola", 950], ["mika", 1100],
  ["sven", 2010], ["ola", 1500], ["tara", 1430], ["juno", 1430], ["kai", 80],
  ["rex", 2600], ["lin", 1999], ["kai", 1430], ["ola", 1499]
]

board = Board.new
ignored = []
events.each do |player, pts|
  ignored << "#{player}:#{pts}" unless board.submit(player, pts)
end
puts "leaderboard after #{events.size} submissions (ignored #{ignored}):"
board.show(10)

["juno", "lin", "nobody"].each do |pl|
  r = board.rank(pl)
  puts(r ? "#{pl} is ranked #{r}" : "#{pl} has no score")
end
puts "score needed for top 3: #{board.needed_for_top(3)}"
puts "score needed for top 20: #{board.needed_for_top(20)}"

entries = board.entries
entries.each_cons(2) { |a, b| raise "out of order" if b < a }
puts "in order: #{entries.size} entries, #{board.moves} element moves"
entries.group_by(&:score).select { |_, es| es.size > 1 }.each do |s, es|
  puts "tied at #{s}: #{es.map(&:player).join(", ")}"
end

board.submit("juno", 3000)
puts "juno jumps to rank #{board.rank("juno")}; top is now #{entries.first.player}"
median = entries[entries.size / 2]
puts "median score: #{median.score}"
