# Simulated external merge sort of CSV score records: memory holds only a few
# records, so the input is cut into sorted runs that are merged with a limited
# fan-in, pass after pass. "Disk" is an Array of runs; I/O is counted.

class Record
  attr_reader :player, :score, :line

  def initialize(player, score, line)
    @player = player
    @score = score
    @line = line
  end

  # order: higher score first, then player name
  def before?(other)
    return score > other.score if score != other.score
    player < other.player
  end
end

class Disk
  attr_accessor :reads, :writes

  def initialize(reads, writes)
    @reads = reads
    @writes = writes
  end
end

class BadLine < StandardError
  attr_reader :line_no

  def initialize(message, line_no)
    super(message)
    @line_no = line_no
  end
end

def parse(csv)
  out = []
  csv.lines.each_with_index do |raw, i|
    line = raw.strip
    next if line.empty? || line.start_with?("#")
    fields = line.split(",")
    raise BadLine.new("expected 2 fields, got #{fields.size}", i + 1) if fields.size != 2
    begin
      score = Integer(fields[1].strip)
    rescue ArgumentError
      raise BadLine.new("bad score #{fields[1].strip}", i + 1)
    end
    out << Record.new(fields[0].strip, score, i + 1)
  end
  out
end

def insertion_sort(a)
  (1...a.size).each do |i|
    x = a[i]
    j = i - 1
    while j >= 0 && x.before?(a[j])
      a[j + 1] = a[j]
      j -= 1
    end
    a[j + 1] = x
  end
  a
end

def make_runs(records, memory, disk)
  records.each_slice(memory).map do |chunk|
    disk.reads += chunk.size
    run = insertion_sort(chunk.dup)
    disk.writes += chunk.size
    run
  end
end

def merge_group(group, disk)
  pos = group.map { 0 }
  out = []
  loop do
    best = nil
    group.each_with_index do |run, k|
      next if pos[k] >= run.size
      best = k if !best     || run[pos[k]].before?(group[best][pos[best]])
    end
    break if !best    
    out << group[best][pos[best]]
    pos[best] += 1
    disk.reads += 1
    disk.writes += 1
  end
  out
end

def external_sort(records, memory, fan_in)
  disk = Disk.new(0, 0)
  runs = make_runs(records, memory, disk)
  sizes = [runs.size]
  while runs.size > 1
    runs = runs.each_slice(fan_in).map { |group| merge_group(group, disk) }
    sizes << runs.size
  end
  [runs.empty? ? [] : runs[0], sizes, disk]
end

csv = <<~CSV
  # player, score
  aki, 340
  bo, 512
  chen, 298
  dara, 512
  eli, 77
  fumi, 430
  gus, 298
  hana, 615
  ivo, 512
  jun, 150
  kim, 430
  lev, 299
  mai, 88
  noor, 702
  oto, 340
  pia, 512
  quin, 5
CSV

records = parse(csv)
puts "#{records.size} records"
[[3, 2], [4, 4], [5, 3], [17, 2]].each do |memory, fan_in|
  _, sizes, disk = external_sort(records, memory, fan_in)
  puts format("memory=%-2d fan-in=%d runs per pass %-14s reads=%3d writes=%3d",
              memory, fan_in, sizes.join("->"), disk.reads, disk.writes)
end

sorted, _, _ = external_sort(records, 3, 2)
sorted.take(6).each_with_index do |r, i|
  puts format("%d. %-5s %4d (line %d)", i + 1, r.player, r.score, r.line)
end
puts "last: #{sorted.last.player}"
sorted.group_by(&:score).each do |score, rs|
  puts "tie at #{score}: #{rs.map(&:player).join(", ")}" if rs.size > 1
end

["zed, 10\nyan 20\n", "zed, 10\nyan, lots\n"].each do |bad|
  parse(bad)
rescue BadLine => e
  puts "line #{e.line_no}: #{e.message}"
end
