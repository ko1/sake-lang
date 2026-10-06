Passenger = Struct.new(:id, :time, :from, :to, :picked, :dropped) do
  def dir = to > from ? :up : :down
end

def ints(line, n)
  w = line.split
  return nil unless w.size == n && w.all? { _1.match?(/\A\d+\z/) }
  w.map(&:to_i)
end

def fmt(h) = h.even? ? (h / 2).to_s : "#{h / 2}.5"

lines = $stdin.read.split("\n")
hw = (lines[0] || "").split
head = nil
if hw.size == 3 && hw[0].match?(/\A\d+\z/) && hw[2].match?(/\A\d+\z/) && hw[1].match?(/\A\d+(\.5)?\z/)
  d2 = hw[1].to_i * 2 + (hw[1].end_with?(".5") ? 1 : 0)
  head = [hw[0].to_i, d2, hw[2].to_i]
end
unless head && head[0].between?(2, 50) && head[1].between?(0, 10) && head[2].between?(1, 20)
  puts "invalid header"
  exit
end
floors, door, cap = head
pending = []
last = 0
lines.each_with_index do |line, i|
  next if i == 0 || line.strip.empty?
  r = ints(line, 3)
  if r && r[0] <= 1000 && r[0] >= last && r[1].between?(1, floors) && r[2].between?(1, floors) && r[1] != r[2]
    last = r[0]
    pending << Passenger.new(pending.size + 1, r[0] * 2, r[1], r[2])
  else
    puts "line #{i + 1}: invalid request"
  end
end
if pending.empty?
  puts "no passengers"
  exit
end

all = pending.dup
waiting = []
riding = []
floor = 1
dir = :idle
t = 0
until all.all?(&:dropped)
  waiting << pending.shift while pending.first && pending.first.time <= t
  drops = riding.select { _1.to == floor }
  riding -= drops
  drops.each do |pa|
    pa.dropped = t
    puts "t=#{fmt(t)} floor #{floor} drop P#{pa.id}"
  end
  targets = riding.map(&:to) + waiting.map(&:from)
  above = targets.any? { _1 > floor }
  below = targets.any? { _1 < floor }
  dir = case dir
        when :up then above ? :up : (below ? :down : :idle)
        when :down then below ? :down : (above ? :up : :idle)
        else :idle
        end
  if dir == :idle && !targets.empty?
    near = targets.min_by { [(_1 - floor).abs, _1] }
    dir = if near > floor then :up
          elsif near < floor then :down
          else waiting.find { _1.from == floor }.dir
          end
  end
  picks = waiting.select { _1.from == floor && _1.dir == dir }.first(cap - riding.size)
  waiting -= picks
  picks.each do |pa|
    pa.picked = t
    riding << pa
    puts "t=#{fmt(t)} floor #{floor} pick P#{pa.id}"
  end
  if !drops.empty? || !picks.empty?
    t += door
    next
  end
  floor += 1 if dir == :up
  floor -= 1 if dir == :down
  t += 2
end

all.each { |pa| puts "P#{pa.id} wait #{fmt(pa.picked - pa.time)} ride #{fmt(pa.dropped - pa.picked)}" }
n = all.size.to_f
puts format("average wait %.2f ride %.2f", all.sum { _1.picked - _1.time } / n / 2, all.sum { _1.dropped - _1.picked } / n / 2)
puts "done at t=#{fmt(all.map(&:dropped).max)}"
