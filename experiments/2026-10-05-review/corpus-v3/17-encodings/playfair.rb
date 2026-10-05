# Playfair cipher: build the 5x5 key square, split text into digraphs (X padding),
# encrypt and decrypt using the row / column / rectangle rules.

require "set"

class Square
  attr_reader :cells, :where

  def initialize(cells, where)
    @cells = cells
    @where = where
  end

  def self.build(keyword)
    seen = Set.new
    cells = []
    (keyword.upcase + "ABCDEFGHIKLMNOPQRSTUVWXYZ").each_char do |c|
      c = "I" if c == "J"
      next unless c.match?(/[A-Z]/)
      next unless seen.add?(c)
      cells << c
    end
    where = cells.each_with_index.to_h { |c, i| [c, [i / 5, i % 5]] }
    new(cells, where)
  end

  def at(row, col) = @cells.fetch((row % 5) * 5 + col % 5)

  def pos(c)
    p = @where[c]
    raise ArgumentError, "letter #{c} not in square" if p.nil?
    p
  end

  def rows = @cells.each_slice(5).map { |r| r.join(" ") }
end

def prepare(text)
  letters = text.upcase.gsub(/[^A-Z]/, "").chars.map { |c| c == "J" ? "I" : c }
  pairs = []
  i = 0
  while i < letters.size
    a = letters[i]
    b = letters[i + 1]
    if b.nil? || a == b
      pairs << [a, a == "X" ? "Q" : "X"]
      i += 1
    else
      pairs << [a, b]
      i += 2
    end
  end
  pairs
end

def transform(sq, pairs, shift)
  pairs.map do |a, b|
    ra, ca = sq.pos(a)
    rb, cb = sq.pos(b)
    if ra == rb
      sq.at(ra, ca + shift) + sq.at(rb, cb + shift)
    elsif ca == cb
      sq.at(ra + shift, ca) + sq.at(rb + shift, cb)
    else
      sq.at(ra, cb) + sq.at(rb, ca)
    end
  end.join
end

def encrypt(sq, text) = transform(sq, prepare(text), 1)

def decrypt(sq, cipher) = transform(sq, cipher.scan(/../).map(&:chars), 4)

def groups(s) = s.scan(/.{1,5}/).join(" ")

sq = Square.build("playfair example")
sq.rows.each { |r| puts r }

["Hide the gold in the tree stump", "Jazz balloon", "Meet me at noon x"].each do |msg|
  pairs = prepare(msg)
  enc = encrypt(sq, msg)
  dec = decrypt(sq, enc)
  puts "plain : #{msg}"
  puts "pairs : #{pairs.map(&:join).join(" ")}"
  puts "cipher: #{groups(enc)}"
  puts "back  : #{groups(dec)}"
end

other = Square.build("Monarchy")
puts "-- keyword MONARCHY --"
other.rows.each { |r| puts r }
puts groups(encrypt(other, "instruments"))

begin
  other.pos("J")
rescue ArgumentError => e
  puts "lookup failed: #{e.message}"
end
