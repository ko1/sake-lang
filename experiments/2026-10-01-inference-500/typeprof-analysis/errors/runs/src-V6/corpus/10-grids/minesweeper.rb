class Cell
  attr_accessor :mine, :adjacent, :state

  def initialize(mine, adjacent, state)
    @mine = mine
    @adjacent = adjacent
    @state = state
  end
end

class MineHit < StandardError
  attr_reader :row, :col

  def initialize(message, row, col)
    super(message)
    @row = row
    @col = col
  end
end

class Field
  attr_accessor :rows, :cols, :cells, :status

  def initialize(rows, cols, cells, status)
    @rows = rows
    @cols = cols
    @cells = cells
    @status = status
  end

  def self.build(rows, cols, mines)
    cells = Array.new(rows) { Array.new(cols) { Cell.new(false, 0, :hidden) } }
    f = new(rows, cols, cells, :playing)
    mines.each do |r, c|
      cells[r][c].mine = true
      f.around(r, c).each { |nr, nc| cells[nr][nc].adjacent += 1 }
    end
    f
  end

  def around(r, c)
    out = []
    (-1..1).each do |dr|
      (-1..1).each do |dc|
        next if dr == 0 && dc == 0
        nr = r + dr
        nc = c + dc
        out << [nr, nc] if nr >= 0 && nr < @rows && nc >= 0 && nc < @cols
      end
    end
    out
  end

  def at(r, c) = @cells[r][c]

  def reveal(r, c)
    start = at(r, c)
    return 0 if start.state != :hidden
    raise MineHit.new("boom", r, c) if start.mine
    opened = 0
    stack = [[r, c]]
    until stack.empty?
      cr, cc = stack.pop
      cell = at(cr, cc)
      next if cell.state != :hidden || cell.mine
      cell.state = :open
      opened += 1
      stack.concat(around(cr, cc)) if cell.adjacent == 0
    end
    opened
  end

  def toggle_flag(r, c)
    cell = at(r, c)
    case cell.state
    when :hidden then cell.state = :flagged
    when :flagged then cell.state = :hidden
    end
  end

  def won? = @cells.all? { |row| row.all? { |cell| cell.mine || cell.state == :open } }

  def glyph(cell, show_all)
    state = show_all && cell.mine ? :open : cell.state
    case state
    when :hidden then "#"
    when :flagged then "F"
    else
      if cell.mine
        "*"
      else
        cell.adjacent == 0 ? "." : cell.adjacent.to_s
      end
    end
  end

  def render(show_all)
    @cells.map { |row| row.map { |cell| glyph(cell, show_all) }.join }.join("\n")
  end
end

def play(title, rows, cols, mines, moves)
  puts "=== #{title} ==="
  f = Field.build(rows, cols, mines)
  moves.each do |kind, r, c|
    break if f.status != :playing
    if kind == :flag
      f.toggle_flag(r, c)
      puts "flag #{r},#{c} -> #{f.at(r, c).state}"
    else
      begin
        n = f.reveal(r, c)
        puts "open #{r},#{c} -> #{n} cells"
        f.status = :won if f.won?
      rescue MineHit => e
        puts "open #{r},#{c} -> #{e.message} at #{e.row},#{e.col}"
        f.status = :lost
      end
    end
  end
  puts f.render(f.status == :lost)
  flags = f.cells.sum { |row| row.count { it.state == :flagged } }
  puts "status: #{f.status}, flags: #{flags}/#{mines.size}"
end

mines = [[0, 3], [1, 6], [3, 1], [4, 4], [5, 7], [6, 0]]
play("careful", 7, 8, mines, [[:open, 0, 0], [:flag, 0, 3], [:open, 6, 7], [:open, 3, 7], [:open, 2, 3],
  [:open, 6, 3], [:open, 3, 0], [:open, 5, 0], [:open, 0, 7], [:open, 4, 0], [:open, 6, 1], [:open, 0, 4], [:open, 0, 5], [:open, 0, 6], [:open, 1, 7], [:open, 6, 0]])
play("reckless", 7, 8, mines, [[:open, 3, 4], [:flag, 4, 4], [:flag, 4, 4], [:open, 4, 4], [:open, 0, 0]])
play("tiny", 2, 2, [[1, 1]], [[:open, 0, 0], [:open, 0, 1], [:open, 1, 0]])
