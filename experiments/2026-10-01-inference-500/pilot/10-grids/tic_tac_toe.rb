# Tic-tac-toe: replay scripted games, reject illegal moves, and let a minimax player finish them.

class IllegalMove < StandardError
  attr_reader :square

  def initialize(message, square)
    super(message)
    @square = square
  end
end

def lines
  [[0, 1, 2], [3, 4, 5], [6, 7, 8], [0, 3, 6], [1, 4, 7], [2, 5, 8], [0, 4, 8], [2, 4, 6]]
end

def other(mark) = mark == :x ? :o : :x

class Move
  include Comparable
  attr_reader :square, :score, :depth

  def initialize(square, score, depth)
    @square = square
    @score = score
    @depth = depth
  end

  def <=>(b)
    by_score = @score <=> b.score
    return by_score if by_score != 0
    by_depth = b.depth <=> @depth
    return by_depth if by_depth != 0
    b.square <=> @square
  end
end

class Board
  attr_reader :squares, :turn

  def initialize(squares, turn)
    @squares = squares
    @turn = turn
  end

  def self.empty = Board.new((0...9).to_a.map { nil }, :x)

  def winner
    line = lines.find do |l|
      i, j, k = l
      m = @squares[i]
      m != nil && @squares[j] == m && @squares[k] == m
    end
    return nil unless line
    i, _j, _k = line
    @squares[i]
  end

  def free = (0...9).to_a.select { |i| @squares[i] == nil }

  def outcome
    w = winner
    return [:win, w] if w
    return [:draw, nil] if free.empty?
    [:playing, nil]
  end

  def play(sq)
    raise IllegalMove.new("square #{sq} is off the board", sq) unless sq.between?(0, 8)
    raise IllegalMove.new("square #{sq} is taken by #{@squares[sq]}", sq) if @squares[sq]
    @squares[sq] = @turn
    @turn = other(@turn)
    self
  end

  def undo(sq)
    @squares[sq] = nil
    @turn = other(@turn)
  end

  def negamax(depth)
    w = winner
    return Move.new(nil, depth - 10, depth) if w
    moves = free
    return Move.new(nil, 0, depth) if moves.empty?
    results = moves.map do |sq|
      play(sq)
      reply = negamax(depth + 1)
      undo(sq)
      Move.new(sq, -reply.score, reply.depth)
    end
    results.max
  end

  def to_s
    rows = [0, 3, 6].map do |r|
      (r...r + 3).to_a.map { |i| m = @squares[i]; m ? m.to_s : i.to_s }.join(" ")
    end
    rows.join("\n")
  end
end

def describe(b)
  state, mark = b.outcome
  case state
  in :win then "#{mark} wins"
  in :draw then "draw"
  in :playing then "#{b.turn} to move"
  end
end

def run(name, script)
  b = Board.empty
  puts("== #{name} ==")
  script.each do |sq|
    begin
      b.play(sq)
    rescue IllegalMove => e
      puts("illegal: #{e.message}")
    end
    break if b.winner
  end
  until b.winner || b.free.empty?
    best = b.negamax(0)
    sq = best.square
    puts("#{b.turn} plays #{sq} (score #{best.score})")
    b.play(sq)
  end
  puts(b)
  puts(describe(b))
  puts
end

run("opposite corners", [0, 4, 8])
run("blunder", [4, 1, 0])
run("x fork", [0, 4, 8, 2, 6])
run("illegal moves", [4, 4, 9, 0, 2, 6])
run("finished", [0, 3, 1, 4, 2, 5])
