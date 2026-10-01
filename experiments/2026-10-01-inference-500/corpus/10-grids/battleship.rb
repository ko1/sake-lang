require "set"

class PlacementError < StandardError
  attr_reader :ship

  def initialize(message, ship)
    super(message)
    @ship = ship
  end
end

class BadCoordinate < StandardError
  attr_reader :text

  def initialize(message, text)
    super(message)
    @text = text
  end
end

module Coord
  module_function

  def parse(text, size)
    m = text.strip.upcase.match(/\A([A-Z])(\d+)\z/)
    raise BadCoordinate.new("cannot read coordinate", text) unless m
    row = m[1].ord - "A".ord
    col = m[2].to_i - 1
    raise BadCoordinate.new("off the board", text) if row >= size || col < 0 || col >= size
    [row, col]
  end

  def name(pos)
    r, c = pos
    "#{("A".ord + r).chr}#{c + 1}"
  end
end

class Ship
  attr_reader :name, :cells, :hits

  def initialize(name, cells, hits)
    @name = name
    @cells = cells
    @hits = hits
  end

  def sunk? = @hits.size == @cells.size

  def occupies?(pos) = @cells.include?(pos)
end

class Ocean
  attr_reader :size, :ships, :shots

  def initialize(size, ships, shots)
    @size = size
    @ships = ships
    @shots = shots
  end

  def self.create(size) = new(size, [], {})

  def place(name, start, length, dir)
    r, c = Coord.parse(start, @size)
    dr, dc = dir == :across ? [0, 1] : [1, 0]
    cells = (0...length).map { |i| [r + dr * i, c + dc * i] }
    cells.each do |cell|
      cr, cc = cell
      raise PlacementError.new("runs off the board at #{Coord.name(cell)}", name) if cr >= @size || cc >= @size
      clash = ship_at(cell)
      raise PlacementError.new("overlaps #{clash.name} at #{Coord.name(cell)}", name) if clash
    end
    @ships << Ship.new(name, cells, Set.new)
  end

  def fire(text)
    pos = Coord.parse(text, @size)
    return :repeat if @shots.key?(pos)
    target = ship_at(pos)
    unless target
      @shots[pos] = :miss
      return :miss
    end
    @shots[pos] = :hit
    target.hits << pos
    target.sunk? ? :sunk : :hit
  end

  def ship_at(pos) = @ships.find { |s| s.occupies?(pos) }

  def defeated? = @ships.all?(&:sunk?)

  def to_s
    header = "   #{(1..@size).map { it.to_s.ljust(2) }.join}"
    rows = (0...@size).map do |r|
      cells = (0...@size).map do |c|
        case @shots[[r, c]]
        when :hit then "X "
        when :miss then "o "
        else ship_at([r, c]) ? "# " : ". "
        end
      end
      "#{("A".ord + r).chr}  #{cells.join.rstrip}"
    end
    [header, *rows].join("\n")
  end
end

def setup(o, fleet)
  fleet.each do |name, start, length, dir|
    o.place(name, start, length, dir)
    puts "placed #{name} at #{start} #{dir}"
  rescue PlacementError => e
    puts "cannot place #{e.ship}: #{e.message}"
  rescue BadCoordinate => e
    puts "cannot place #{name}: #{e.message} (#{e.text})"
  end
end

ocean = Ocean.create(8)
setup(ocean, [
  ["carrier", "B2", 5, :across],
  ["battleship", "A8", 4, :down],
  ["cruiser", "D4", 3, :down],
  ["submarine", "C3", 3, :down],
  ["destroyer", "G6", 2, :across],
  ["patrol", "H1", 3, :across],
  ["raft", "A4", 2, :down],
  ["dinghy", "Z9", 1, :across],
  ["sloop", "F7", 4, :across],
])
puts ocean

shots = %w[b2 B3 C5 d4 E4 F4 a8 B8 C8 D8 G6 g7 q1 B4 B5 B6 B2 H1 H2 H3 A1 C3 D3 E3 A2]
tally = Hash.new(0)
shots.each do |shot|
  begin
    result = ocean.fire(shot)
    tally[result] += 1
    if result == :sunk
      sunk = ocean.ship_at(Coord.parse(shot, ocean.size))
      puts "#{shot}: sunk #{sunk ? sunk.name : "?"}"
    else
      puts "#{shot}: #{result}"
    end
  rescue BadCoordinate => e
    tally[:invalid] += 1
    puts "#{shot}: #{e.message}"
  end
  if ocean.defeated?
    puts "fleet destroyed"
    break
  end
end
puts ocean
afloat = ocean.ships.reject(&:sunk?).map(&:name)
puts "afloat: #{afloat.join(", ")}"
puts tally.keys.sort_by(&:to_s).map { |k| "#{k}=#{tally[k]}" }.join(" ")
