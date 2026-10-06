lines = $stdin.read.split("\n")
cands = (lines[0] || "").split(" ").uniq
if cands.empty?
  puts "no candidates"; exit
end
ballots = []
rej = []
lines[1..].each_with_index do |raw, i|
  n = i + 2
  ln = raw.chomp("\r")
  next if ln =~ /\A *\z/
  seen = []
  err = nil
  ln.split(">", -1).each do |x|
    x = x.strip
    if x.empty? then err = "empty rank"
    elsif !cands.include?(x) then err = "unknown candidate #{x}"
    elsif seen.include?(x) then err = "duplicate #{x}"
    end
    break if err
    seen << x
  end
  err ? rej << "rejected line #{n}: #{err}" : ballots << seen
end
puts rej
puts "ballots: #{ballots.size} valid, #{rej.size} rejected"
alive = cands.dup
hist = Hash.new { |h, k| h[k] = [] }
round = 0
loop do
  round += 1
  counts = alive.to_h { |c| [c, 0] }
  active = 0
  ballots.each do |b|
    c = b.find { |x| alive.include?(x) }
    next unless c
    counts[c] += 1; active += 1
  end
  alive.each { |c| hist[c] << counts[c] }
  puts "round #{round}"
  alive.sort_by { |c| [-counts[c], c.b] }.each do |c|
    t = active == 0 ? 0 : (counts[c] * 2000 + active) / (2 * active)
    puts "  #{c} #{counts[c]} #{t / 10}.#{t % 10}%"
  end
  puts "  exhausted #{ballots.size - active}"
  if active == 0
    puts "no winner"; break
  end
  w = alive.find { |c| counts[c] * 2 > active }
  if w
    puts "winner #{w}"; break
  end
  tied = alive.select { |c| counts[c] == counts.values.min }
  k = round - 2
  while tied.size > 1 && k >= 0
    m = tied.map { |c| hist[c][k] }.min
    tied = tied.select { |c| hist[c][k] == m }
    k -= 1
  end
  e = tied.max_by(&:b)
  puts "  eliminated #{e}"
  alive.delete(e)
end
