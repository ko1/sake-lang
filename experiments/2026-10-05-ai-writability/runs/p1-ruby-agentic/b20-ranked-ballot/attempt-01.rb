lines = $stdin.binmode.read.each_line.map(&:chomp)
cands = (lines[0] || "").split(" ").uniq
if cands.empty?
  puts "no candidates"; exit
end
valid = []
rej = []
lines[1..].to_a.each_with_index do |ln, i|
  no = i + 2
  next if ln =~ /\A *\z/
  names = ln.split(">", -1).map { |x| x.gsub(/\A +| +\z/, "") }
  seen = {}
  reason = nil
  names.each do |n|
    if n.empty? then reason = "empty rank"
    elsif !cands.include?(n) then reason = "unknown candidate #{n}"
    elsif seen[n] then reason = "duplicate #{n}"
    end
    break if reason
    seen[n] = true
  end
  if reason
    rej << "rejected line #{no}: #{reason}"
  else
    valid << names
  end
end
puts rej
puts "ballots: #{valid.size} valid, #{rej.size} rejected"
alive = cands.dup
hist = Hash.new { |h, k| h[k] = [] }
round = 0
loop do
  round += 1
  cnt = alive.to_h { |c| [c, 0] }
  active = 0
  valid.each do |b|
    c = b.find { |x| cnt.key?(x) }
    next unless c
    cnt[c] += 1
    active += 1
  end
  cnt.each { |c, v| hist[c] << v }
  puts "round #{round}"
  cnt.sort_by { |c, v| [-v, c.b] }.each do |c, v|
    tenths = active.zero? ? 0 : (v * 2000 + active) / (2 * active)
    puts "  #{c} #{v} #{tenths / 10}.#{tenths % 10}%"
  end
  puts "  exhausted #{valid.size - active}"
  if active.zero?
    puts "no winner"; break
  end
  w = cnt.find { |_, v| v * 2 > active }
  if w
    puts "winner #{w[0]}"; break
  end
  tied = alive.select { |c| cnt[c] == cnt.values.min }
  (round - 2).downto(0) do |k|
    break if tied.size == 1
    m = tied.map { |c| hist[c][k] }.min
    tied = tied.select { |c| hist[c][k] == m }
  end
  out = tied.max_by(&:b)
  puts "  eliminated #{out}"
  alive.delete(out)
end
