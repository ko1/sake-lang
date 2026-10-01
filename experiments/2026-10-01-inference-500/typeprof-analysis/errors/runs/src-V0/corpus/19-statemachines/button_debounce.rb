class Edge
  attr_reader :kind, :time

  def initialize(kind, time)
    @kind = kind
    @time = time
  end
end

class Gesture
  attr_reader :name, :start, :finish

  def initialize(name, start, finish)
    @name = name
    @start = start
    @finish = finish
  end
end

class Debouncer
  attr_reader :threshold, :edges, :state, :count

  def initialize(threshold)
    @threshold = threshold
    @edges = []
    @state = :released
    @count = 0
  end

  def feed(t, level)
    case @state
    in :released
      if level == 1
        @state = :maybe_pressed
        @count = 1
      end
    in :maybe_pressed
      if level == 1
        @count += 1
        if @count >= @threshold
          @state = :pressed
          @edges << Edge.new(:down, t - @threshold + 1)
        end
      else
        @state = :released
      end
    in :pressed
      if level == 0
        @state = :maybe_released
        @count = 1
      end
    in :maybe_released
      if level == 0
        @count += 1
        if @count >= @threshold
          @state = :released
          @edges << Edge.new(:up, t - @threshold + 1)
        end
      else
        @state = :pressed
      end
    end
  end
end

LONG_PRESS = 12
DOUBLE_GAP = 6

def gestures(edges)
  found = []
  state = :idle
  down_at = 0
  first_click = nil
  edges.each do |e|
    t = e.time
    if state == :waiting_second && t - first_click.time > DOUBLE_GAP
      found << Gesture.new("click", first_click.time, first_click.time)
      state = :idle
    end
    case e.kind
    in :down
      down_at = t
      state = state == :waiting_second ? :second_down : :down
    in :up
      held = t - down_at
      if held >= LONG_PRESS
        found << Gesture.new("long-press", down_at, t)
        state = :idle
      elsif state == :second_down
        found << Gesture.new("double-click", first_click.time, t)
        state = :idle
      else
        first_click = Edge.new(:click, down_at)
        state = :waiting_second
      end
    end
  end
  if state == :waiting_second && first_click
    found << Gesture.new("click", first_click.time, first_click.time)
  end
  found
end

signal = "0001011100000000111100111100000000000111111111111111000000001101111000000011110000000"
[2, 3].each do |threshold|
  d = Debouncer.new(threshold)
  t = 0
  signal.each_char do |ch|
    d.feed(t, ch.to_i)
    t += 1
  end
  edges = d.edges
  puts "threshold #{threshold}: #{edges.size} edges, final state #{d.state}"
  puts "  " + edges.map { |e| "#{e.kind}@#{e.time}" }.join(" ")
  gestures(edges).each do |g|
    puts format("  %-12s %3d..%-3d", g.name, g.start, g.finish)
  end
end
