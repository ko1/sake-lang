require "set"

class Piece
  attr_reader :kind, :white

  LETTERS = { king: "k", queen: "q", rook: "r", bishop: "b", knight: "n", pawn: "p" }.freeze
  VALUES = { queen: 9, rook: 5, bishop: 3, knight: 3, pawn: 1, king: 0 }.freeze

  def initialize(kind, white)
    @kind = kind
    @white = white
  end

  def letter
    ch = LETTERS.fetch(@kind)
    @white ? ch.upcase : ch
  end

  def value = VALUES.fetch(@kind)
end

KINDS = { "k" => :king, "q" => :queen, "r" => :rook, "b" => :bishop, "n" => :knight, "p" => :pawn }.freeze

# board: Hash from [rank, file] (0-based, rank 0 = rank 1) to Piece
def parse_fen(fen)
  board = {}
  fen.split("/").each_with_index do |row, i|
    rank = 7 - i
    file = 0
    row.each_char do |ch|
      if ch.match?(/\d/)
        file += ch.to_i
      else
        kind = KINDS[ch.downcase]
        raise ArgumentError, "bad piece #{ch}" unless kind
        board[[rank, file]] = Piece.new(kind, ch == ch.upcase)
        file += 1
      end
    end
  end
  board
end

def square_name((rank, file)) = "#{(97 + file).chr}#{rank + 1}"

def on_board?(rank, file) = rank.between?(0, 7) && file.between?(0, 7)

STRAIGHT = [[1, 0], [-1, 0], [0, 1], [0, -1]].freeze
DIAGONAL = [[1, 1], [1, -1], [-1, 1], [-1, -1]].freeze

def rays(kind)
  case kind
  when :rook then STRAIGHT
  when :bishop then DIAGONAL
  when :queen then STRAIGHT + DIAGONAL
  else []
  end
end

def steps(kind, white)
  case kind
  when :knight then [[2, 1], [1, 2], [-1, 2], [-2, 1], [-2, -1], [-1, -2], [1, -2], [2, -1]]
  when :king then STRAIGHT + DIAGONAL
  when :pawn then white ? [[1, -1], [1, 1]] : [[-1, -1], [-1, 1]]
  else []
  end
end

def attacks_from(board, sq, piece)
  rank, file = sq
  out = steps(piece.kind, piece.white).map { |dr, df| [rank + dr, file + df] }.select { |r, f| on_board?(r, f) }
  rays(piece.kind).each do |dr, df|
    r = rank + dr
    f = file + df
    while on_board?(r, f)
      out << [r, f]
      break if board[[r, f]]
      r += dr
      f += df
    end
  end
  out
end

def attacked_by(board, white)
  seen = Set.new
  board.each do |sq, piece|
    next if piece.white != white
    seen.merge(attacks_from(board, sq, piece))
  end
  seen
end

def king_square(board, white)
  board.find { |_sq, piece| piece.kind == :king && piece.white == white }&.first
end

def analyse(name, fen)
  puts "== #{name} =="
  board = parse_fen(fen)
  7.downto(0) do |rank|
    line = (0..7).map { |file| board[[rank, file]]&.letter || "." }
    puts "#{rank + 1} #{line.join}"
  end
  material = [true, false].map do |white|
    board.values.select { |pc| pc.white == white }.sum(&:value)
  end
  puts "material: white #{material[0]}, black #{material[1]}"
  [true, false].each do |white|
    side = white ? "white" : "black"
    king = king_square(board, white)
    unless king
      puts "#{side}: no king!"
      next
    end
    enemy = attacked_by(board, !white)
    in_check = enemy.include?(king)
    kr, kf = king
    escapes = steps(:king, white).select do |dr, df|
      r = kr + dr
      f = kf + df
      target = board[[r, f]]
      on_board?(r, f) && !enemy.include?([r, f]) && (!target     || target.white != white)
    end
    names = escapes.map { |dr, df| square_name([kr + dr, kf + df]) }
    status = if in_check && escapes.empty? then "in check, no king moves"
             elsif in_check then "in check"
             else "safe"
             end
    puts "#{side} king #{square_name(king)}: #{status}; moves #{names.sort.join(" ")}; controls #{attacked_by(board, white).size} squares"
  end
rescue ArgumentError => e
  puts "bad position: #{e.message}"
end

analyse("start", "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR")
analyse("scholar's mate", "r1bqkb1r/pppp1Qpp/2n2n2/4p3/2B1P3/8/PPPP1PPP/RNB1K1NR")
analyse("rook endgame", "8/8/8/4k3/8/8/1R6/R3K3")
analyse("typo", "8/8/8/4x3/8/8/8/4K3")
