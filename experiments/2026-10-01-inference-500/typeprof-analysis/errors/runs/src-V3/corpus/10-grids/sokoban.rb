require "set"

class Snapshot
  attr_reader :boxes, :player, :pushes

  def initialize(boxes, player, pushes)
    @boxes = boxes
    @player = player
    @pushes = pushes
  end
end

def delta(move)
  case move
  in "u" then [-1, 0]
  in "d" then [1, 0]
  in "l" then [0, -1]
  in "r" then [0, 1]
  end
end

class Level
  attr_reader :walls, :goals, :boxes, :player, :width, :height, :history, :pushes

  def initialize(walls, goals, boxes, player, width, height, history, pushes)
    @walls = walls
    @goals = goals
    @boxes = boxes
    @player = player
    @width = width
    @height = height
    @history = history
    @pushes = pushes
  end

  def self.parse(text)
    walls = Set.new
    goals = Set.new
    boxes = Set.new
    player = nil
    rows = text.lines
    rows.each_with_index do |line, r|
      line.chomp.chars.each_with_index do |ch, c|
        pos = [r, c]
        walls << pos if ch == "#"
        goals << pos if ch == "." || ch == "*" || ch == "+"
        boxes << pos if ch == "$" || ch == "*"
        player = pos if ch == "@" || ch == "+"
      end
    end
    raise ArgumentError, "level has no player" unless player
    raise ArgumentError, "#{boxes.size} boxes but #{goals.size} goals" if boxes.size != goals.size
    width = rows.map { it.chomp.size }.max || 0
    new(walls, goals, boxes, player, width, rows.size, [], 0)
  end

  def move(m)
    dr, dc = delta(m)
    r, c = @player
    target = [r + dr, c + dc]
    return :blocked if @walls.include?(target)
    if @boxes.include?(target)
      beyond = [r + 2 * dr, c + 2 * dc]
      return :stuck if @walls.include?(beyond) || @boxes.include?(beyond)
      @history.push(Snapshot.new(@boxes.to_a, @player, @pushes))
      @boxes.delete(target)
      @boxes.add(beyond)
      @pushes += 1
      @player = target
      return :pushed
    end
    @history.push(Snapshot.new(@boxes.to_a, @player, @pushes))
    @player = target
    :moved
  end

  def undo
    snap = @history.pop
    return false unless snap
    @pushes = snap.pushes
    @boxes = snap.boxes.to_set
    @player = snap.player
    true
  end

  def solved? = @boxes.subset?(@goals)

  def to_s
    (0...@height).map do |r|
      (0...@width).map do |c|
        pos = [r, c]
        box = @boxes.include?(pos)
        goal = @goals.include?(pos)
        if @player == pos
          goal ? "+" : "@"
        elsif box
          goal ? "*" : "$"
        elsif @walls.include?(pos)
          "#"
        else
          goal ? "." : " "
        end
      end.join.rstrip
    end.join("\n")
  end
end

def play(name, rows, moves)
  puts "### #{name}"
  lv = Level.parse(rows.join("\n"))
  puts lv
  counts = Hash.new(0)
  moves.each_char do |m|
    if m == "z"
      counts[:undone] += 1 if lv.undo
      next
    end
    counts[lv.move(m)] += 1
  end
  stats = counts.keys.sort_by(&:to_s).map { |k| "#{k}=#{counts[k]}" }
  puts "moves: #{moves.size} (#{stats.join(", ")}), pushes kept: #{lv.pushes}"
  puts lv
  on_goal = (lv.boxes & lv.goals).size
  puts(lv.solved? ? "SOLVED" : "unsolved: #{on_goal}/#{lv.goals.size} boxes on goals")
rescue ArgumentError => e
  puts "cannot load: #{e.message}"
end

play("first steps", ['#######', '#     #', '# $@. #', '#     #', '#######'], "uulldrr")
play("two boxes", ['########', '#  .   #', '# $$ @ #', '#  .   #', '########'], "lzulldullddrulur")
play("corner trap", ['#####', '#@$.#', '# $ #', '#.  #', '#####'], "rdlddrzzdrr")
play("no player", ['####', '#$.#', '####'], "r")
play("mismatch", ['#####', '#@$$#', '#. ##', '#####'], "")
