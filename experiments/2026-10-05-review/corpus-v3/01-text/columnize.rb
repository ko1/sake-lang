class Layout
  attr_reader :rows, :cols, :widths, :order

  def initialize(rows, cols, widths, order)
    @rows = rows
    @cols = cols
    @widths = widths
    @order = order
  end

  def cell_index(r, c)
    order == :down ? c * rows + r : r * cols + c
  end
end

def try_layout(items, cols, order, gap, width)
  rows = items.size.ceildiv(cols)
  layout = Layout.new(rows, cols, [], order)
  cols.times do |c|
    w = (0...rows).map { |r| items[layout.cell_index(r, c)] }.compact.map(&:size).max || 0
    layout.widths << w
  end
  total = layout.widths.sum + gap * (cols - 1)
  total <= width ? layout : nil
end

def best_layout(items, order, gap, width)
  best = Layout.new(items.size, 1, [items.map(&:size).max], order)
  (2..items.size).each do |cols|
    layout = try_layout(items, cols, order, gap, width)
    best = layout if layout && layout.rows < best.rows
  end
  best
end

def render(items, layout, gap)
  (0...layout.rows).map do |r|
    cells = (0...layout.cols).filter_map do |c|
      item = items[layout.cell_index(r, c)]
      item&.ljust(layout.widths[c])
    end
    cells.join(" " * gap).rstrip
  end
end

def show(title, items, order, width)
  layout = best_layout(items, order, 2, width)
  puts "#{title}: #{items.size} items, width #{width}, #{layout.cols} columns x #{layout.rows} rows (#{order})"
  puts "|" + "-" * (width - 2) + "|"
  render(items, layout, 2).each { |l| puts l }
  puts
end

def files
  ("Gemfile Gemfile.lock README.md Rakefile app bin config config.ru db lib log public " \
   "storage test tmp vendor .gitignore .ruby-version Procfile docker-compose.yml").split(" ")
end

def ruby_methods
  ["each", "map", "select", "reject", "reduce", "each_with_index", "each_with_object",
   "group_by", "partition", "zip", "flat_map", "min_by", "max_by", "sum", "tally", "sort_by",
   "take_while", "drop_while", "chunk_while", "slice_when", "each_slice", "each_cons"]
end

show("files", files, :down, 60)
show("files", files, :across, 60)
show("methods", ruby_methods.sort, :down, 72)
show("methods", ruby_methods.sort, :down, 40)
show("single", ["only-one-entry"], :down, 20)
show("too wide", ["a-very-long-entry-name-that-does-not-fit", "short"], :down, 20)
