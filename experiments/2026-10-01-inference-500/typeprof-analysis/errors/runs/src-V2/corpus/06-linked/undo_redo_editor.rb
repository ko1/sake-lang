class Cell
  attr_reader :item, :under

  def initialize(item, under)
    @item = item
    @under = under
  end
end

class Insert
  attr_reader :pos, :text

  def initialize(pos, text)
    @pos = pos
    @text = text
  end
end

class Delete
  attr_reader :pos, :removed

  def initialize(pos, removed)
    @pos = pos
    @removed = removed
  end
end

class Replace
  attr_reader :pos, :old, :new

  def initialize(pos, old, new)
    @pos = pos
    @old = old
    @new = new
  end
end

class NothingToUndo < StandardError
  attr_reader :which

  def initialize(message, which)
    super(message)
    @which = which
  end
end

class Editor
  attr_reader :text

  def initialize(text)
    @text = text
    @undos = nil
    @redos = nil
    @saved_depth = 0
    @depth = 0
  end

  def insert(pos, s) = run(Insert.new(pos, s))
  def delete(pos, len) = run(Delete.new(pos, @text[pos...(pos + len)]))

  def replace_all(from, to)
    start = 0
    while (j = @text[start..].index(from))
      i = start + j
      run(Replace.new(i, from, to))
      start = i + to.size
    end
  end

  def undo!
    top = @undos
    raise NothingToUndo.new("nothing to undo", "undo") unless top
    apply(inverse(top.item))
    @undos = top.under
    @redos = Cell.new(top.item, @redos)
    @depth -= 1
  end

  def redo!
    top = @redos
    raise NothingToUndo.new("nothing to redo", "redo") unless top
    apply(top.item)
    @redos = top.under
    @undos = Cell.new(top.item, @undos)
    @depth += 1
  end

  def save = @saved_depth = @depth
  def dirty? = @depth != @saved_depth

  def status = format("%-34s undo=%d redo=%d%s", @text.inspect, stack_size(@undos), stack_size(@redos), dirty? ? " *" : "")

  private

  def splice(pos, len, s) = @text = @text[0...pos] + s + @text[(pos + len)..]

  def apply(cmd)
    case cmd
    when Insert then splice(cmd.pos, 0, cmd.text)
    when Delete then splice(cmd.pos, cmd.removed.size, "")
    when Replace then splice(cmd.pos, cmd.old.size, cmd.new)
    end
  end

  def inverse(cmd)
    case cmd
    when Insert then Delete.new(cmd.pos, cmd.text)
    when Delete then Insert.new(cmd.pos, cmd.removed)
    when Replace then Replace.new(cmd.pos, cmd.new, cmd.old)
    end
  end

  def run(cmd)
    apply(cmd)
    @undos = Cell.new(cmd, @undos)
    @redos = nil
    @depth += 1
  end

  def stack_size(cell)
    n = 0
    while cell
      n += 1
      cell = cell.under
    end
    n
  end
end

ed = Editor.new("hello world")
puts ed.status
script = [
  [:insert, 5, ","], [:insert, 12, "!"], [:save, 0, ""], [:delete, 0, "1"], [:insert, 0, "H"],
  [:undo, 0, ""], [:undo, 0, ""], [:redo, 0, ""], [:replace, 0, "o|0"], [:undo, 0, ""],
  [:undo, 0, ""], [:insert, 6, " big"], [:redo, 0, ""], [:undo, 0, ""], [:undo, 0, ""],
  [:undo, 0, ""], [:undo, 0, ""], [:undo, 0, ""], [:redo, 0, ""]
]
script.each do |op, pos, arg|
  begin
    case op
    when :insert then ed.insert(pos, arg)
    when :delete then ed.delete(pos, arg.to_i)
    when :replace then ed.replace_all(*arg.split("|"))
    when :undo then ed.undo!
    when :redo then ed.redo!
    when :save then ed.save
    end
    puts format("%-8s %s", op, ed.status)
  rescue NothingToUndo => e
    puts format("%-8s error: %s (%s)", op, e.message, e.which)
  end
end
