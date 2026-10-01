class Phase
  attr_reader :name, :ns, :ew, :walk, :min_time, :max_time

  def initialize(name, ns, ew, walk, min_time, max_time)
    @name = name
    @ns = ns
    @ew = ew
    @walk = walk
    @min_time = min_time
    @max_time = max_time
  end
end

PHASES = {
  ns_green: Phase.new("NS green", :green, :red, false, 4, 10),
  ns_yellow: Phase.new("NS yellow", :yellow, :red, false, 2, 2),
  all_red_1: Phase.new("all red", :red, :red, false, 1, 1),
  ew_green: Phase.new("EW green", :red, :green, false, 4, 8),
  ew_yellow: Phase.new("EW yellow", :red, :yellow, false, 2, 2),
  all_red_2: Phase.new("all red", :red, :red, false, 1, 1),
  walk: Phase.new("WALK", :red, :red, true, 5, 5),
  emergency: Phase.new("EMERGENCY", :red, :red, false, 1, 99)
}

def cycle_next(phase, ped_waiting)
  case phase
  in :ns_green then :ns_yellow
  in :ns_yellow then :all_red_1
  in :all_red_1 then :ew_green
  in :ew_green then :ew_yellow
  in :ew_yellow then :all_red_2
  in :all_red_2 then ped_waiting ? :walk : :ns_green
  in :walk then :ns_green
  in :emergency then :all_red_2
  end
end

class Controller
  attr_reader :phase, :elapsed, :ped_waiting, :preempt, :history

  def initialize
    @phase = :ns_green
    @elapsed = 0
    @ped_waiting = false
    @preempt = false
    @history = []
  end

  def current = PHASES[@phase]

  def switch_to(t, nxt)
    @history << [t, nxt]
    @phase = nxt
    @elapsed = 0
    @ped_waiting = false if nxt == :walk
  end

  def tick(t, input)
    @ped_waiting = true if input.include?(:button)
    if input.include?(:siren)
      @preempt = true
    elsif input.include?(:clear)
      @preempt = false
    end
    @elapsed += 1
    ph = current
    if @preempt && @phase != :emergency
      if ph.ns == :green || ph.ew == :green
        switch_to(t, @phase == :ns_green ? :ns_yellow : :ew_yellow)
      elsif ph.ns == :red && ph.ew == :red && !ph.walk
        switch_to(t, :emergency)
      elsif @elapsed >= ph.min_time
        switch_to(t, ph.walk ? :emergency : cycle_next(@phase, false))
      end
      return
    end
    return if @phase == :emergency && @preempt
    return if @elapsed < ph.min_time
    green_dir = ph.ns == :green ? :ns_car : (ph.ew == :green ? :ew_car : nil)
    hold = green_dir && input.include?(green_dir) && !@ped_waiting
    return if hold && @elapsed < ph.max_time
    switch_to(t, cycle_next(@phase, @ped_waiting))
  end
end

def lamp(color)
  case color
  in :green then "G"
  in :yellow then "Y"
  in :red then "R"
  end
end

inputs = {
  2 => Set[:ns_car], 3 => Set[:ns_car], 4 => Set[:ns_car], 5 => Set[:ns_car, :button],
  12 => Set[:ew_car], 13 => Set[:ew_car], 14 => Set[:ew_car], 15 => Set[:ew_car], 16 => Set[:ew_car],
  30 => Set[:siren], 31 => Set[:siren], 35 => Set[:clear], 41 => Set[:button]
}
c = Controller.new
line = +""
(0..59).each do |t|
  c.tick(t, inputs.fetch(t, Set[]))
  ph = c.current
  cell = ph.walk ? "W" : (c.phase == :emergency ? "!" : lamp(ph.ns) + lamp(ph.ew))
  line << cell.ljust(3)
  if t % 20 == 19
    puts format("t=%02d-%02d %s", t - 19, t, line)
    line = +""
  end
end
puts "phase changes:"
c.history.each do |t, ph|
  puts format("  t=%02d %s", t, PHASES[ph].name)
end
counts = c.history.map { |t, ph| ph }.tally
puts counts.keys.sort_by(&:to_s).map { |k| "#{k}=#{counts[k]}" }.join(" ")
