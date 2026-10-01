require "set"

class Todo
  attr_reader :id, :title, :priority, :due, :tags
  attr_accessor :done

  def initialize(id, title, priority, due, tags, done)
    @id = id
    @title = title
    @priority = priority
    @due = due
    @tags = tags
    @done = done
  end
end

class CommandError < StandardError
  attr_reader :line

  def initialize(message, line)
    super(message)
    @line = line
  end
end

PRIORITY_RANK = { high: 0, normal: 1, low: 2 }

def parse_priority(s, lineno)
  case s
  when "!!" then :high
  when "!" then :normal
  when "." then :low
  else raise CommandError.new("bad priority '#{s}'", lineno)
  end
end

class TodoList
  attr_reader :items

  def initialize
    @items = []
    @next_id = 1
  end

  def add(title, priority, due, tags)
    t = Todo.new(@next_id, title, priority, due, tags, false)
    @next_id += 1
    @items << t
    t
  end

  def find(id) = @items.find { |t| t.id == id }

  def complete(id, lineno)
    t = find(id)
    raise CommandError.new("no todo ##{id}", lineno) unless t
    raise CommandError.new("##{id} is already done", lineno) if t.done
    t.done = true
    t
  end

  def ordered
    @items.sort_by { |t| [PRIORITY_RANK.fetch(t.priority), t.due, t.id] }
  end

  def pending = ordered.reject(&:done)

  def tagged(tag) = ordered.select { |t| t.tags.include?(tag) }
end

def show(t)
  mark = t.done ? "x" : " "
  tags = t.tags.sort.map { |g| "##{g}" }.join(" ")
  format("[%s] %3d %-6s %s  %-24s %s", mark, t.id, t.priority, t.due, t.title, tags)
end

def run(list, script)
  script.lines.each_with_index do |raw, i|
    lineno = i + 1
    line = raw.strip
    next if line.empty? || line.start_with?("#")
    begin
      cmd, rest = line.split(" ", 2)
      case cmd
      when "add"
        m = rest.match(/\A(\S+) (\d\d-\d\d) (.*)\z/)
        raise CommandError.new("cannot parse '#{rest}'", lineno) unless m
        tag_words, title_words = m[3].split(" ").partition { |w| w.start_with?("#") }
        tags = tag_words.map { |w| w.delete_prefix("#") }.to_set
        t = list.add(title_words.join(" "), parse_priority(m[1], lineno), m[2], tags)
        puts "added ##{t.id} #{t.title}"
      when "done"
        t = list.complete(rest.to_i, lineno)
        puts "done  ##{t.id} #{t.title}"
      when "list"
        puts "-- #{rest} --"
        shown = rest == "all" ? list.ordered : list.tagged(rest)
        shown.each { |t| puts show(t) }
      else
        raise CommandError.new("unknown command '#{cmd}'", lineno)
      end
    rescue CommandError => e
      puts "line #{e.line}: #{e.message}"
    end
  end
end

script = <<~TXT
  # weekly plan
  add !! 10-03 Pay office rent #admin #money
  add ! 10-05 Call the accountant #admin
  add . 10-09 Water the plants #office
  add !! 10-02 Send invoice to Acme #money #clients
  add ! 10-02 Order printer toner #office
  add ? 10-04 Something odd
  add ! tomorrow Fix the sign
  done 4
  done 4
  done 17
  add . 10-03 Book team lunch #team #office
  add ! 10-05 Review contracts #clients #admin
  frobnicate now
  done 2
  list all
  list office
  list clients
TXT

list = TodoList.new
run(list, script)

puts
puts "Pending by priority:"
list.pending.group_by(&:priority).each do |prio, ts|
  puts "  #{prio}: #{ts.map(&:title).join(", ")}"
end

tag_counts = Hash.new(0)
list.items.each do |t|
  t.tags.each { |g| tag_counts[g] += 1 }
end
puts "Tags: " + tag_counts.sort_by { |g, _n| g }.map { |g, n| "#{g}=#{n}" }.join(" ")

done = list.items.count(&:done)
total = list.items.size
puts format("Progress: %d/%d (%.0f%%)", done, total, done * 100.0 / total)
