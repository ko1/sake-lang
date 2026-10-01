LINES = [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]].freeze

def other(player) = player == "X" ? "O" : "X"

class Game
  attr_reader :cells, :memo, :nodes

  def initialize(cells, memo, nodes)
    @cells = cells
    @memo = memo
    @nodes = nodes
  end

  def self.from(text)
    new(text.delete("|").chars.map { |ch| ch == "." ? nil : ch }, {}, 0)
  end

  def winner
    LINES.each do |a, b, c|
      v = @cells[a]
      return v if v && v == @cells[b] && v == @cells[c]
    end
    nil
  end

  def free = (0...9).select { |i| !@cells[i]     }

  def to_move
    @cells.count("X") > @cells.count("O") ? "O" : "X"
  end

  def key = @cells.map { it || "." }.join

  # score from X's point of view: +10 - depth for an X win, -10 + depth for an O win
  def minimax(player, depth)
    @nodes += 1
    k = "#{key}#{player}"
    cached = @memo[k]
    return cached if cached
    w = winner
    result =
      if w == "X"
        10 - depth
      elsif w == "O"
        depth - 10
      elsif free.empty?
        0
      else
        scores = free.map do |i|
          @cells[i] = player
          s = minimax(other(player), depth + 1)
          @cells[i] = nil
          s
        end
        player == "X" ? scores.max : scores.min
      end
    @memo[k] = result
  end

  def best_move
    player = to_move
    best = nil
    best_score = nil
    free.each do |i|
      @cells[i] = player
      s = minimax(other(player), 1)
      @cells[i] = nil
      if !best_score     || (player == "X" ? s > best_score : s < best_score)
        best = i
        best_score = s
      end
    end
    [best, best_score]
  end

  def to_s
    @cells.each_slice(3).map { |row| row.map { it || "." }.join("|") }.join("\n")
  end
end

def verdict(score)
  if score > 0
    "X wins"
  elsif score < 0
    "O wins"
  else
    "draw"
  end
end

def analyse(text)
  g = Game.from(text)
  if (w = g.winner)
    puts "#{text}: already won by #{w}"
    return
  end
  if g.free.empty?
    puts "#{text}: board full, draw"
    return
  end
  move, score = g.best_move
  puts "#{text}: #{g.to_move} plays #{move} -> #{verdict(score)} (score #{score}, #{g.nodes} nodes)"
end

def self_play(text)
  g = Game.from(text)
  puts "self-play from #{text}:"
  until g.winner || g.free.empty?
    player = g.to_move
    move, _score = g.best_move
    g.cells[move] = player
    puts "  #{player} -> #{move}"
  end
  puts g
  w = g.winner
  puts(w ? "winner: #{w}" : "result: draw")
end

analyse("X.O|.X.|...")
analyse("XX.|OO.|...")
analyse("X..|.O.|..X")
analyse("XOX|OXO|OXO")
analyse("XXX|OO.|...")
analyse("O..|.X.|...")
self_play("X..|...|...")
self_play("X.O|...|...")
