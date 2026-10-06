lines = $stdin.read.split("\n", -1)
lines.pop if lines.last == ""
cands = (lines[0] || "").chomp("\r").split(" ").uniq
if cands.empty?
  puts "no candidates"
  exit
end
valid = []
rej = []
lines[1..].each_with_index do |l, i|
  no = i + 2
  l = l.chomp("\r")
  next if l =~ /\A *\z/
  seen = []
  reason = nil
  l.split(">", -1).each do |r|
    nm = r.gsub(/\A +| +\z/, "")
    if nm.empty? then reason = "empty rank"
    elsif !cands.include?(nm) then reason = "unknown candidate #{nm}"
    elsif seen.include?(nm) then reason = "duplicate #{nm}"
    end
    break if reason
    seen << nm
  end
  if reason
    rej << "rejected line #{no}: #{reason}"
  else
    valid << seen
  end
end
puts rej
puts "ballots: #{valid.size} valid, #{rej.size} rejected"
cont = cands.dup
hist = []
round = 0
loop do
  round += 1
  cnt = cont.to_h { |c| [c, 0] }
  active = 0
  valid.each do |b|
    w = b.find { |c| cnt.key?(c) }
    if w then cnt[w] += 1; active += 1 end
  end
  hist << cnt
  puts "round #{round}"
  cont.sort_by { |c| [-cnt[c], c.b] }.each do |c|
    pct = active == 0 ? 0 : (cnt[c] * 2000 + active) / (2 * active)
    puts format("  %s %d %d.%d%%", c, cnt[c], pct / 10, pct % 10)
  end
  puts "  exhausted #{valid.size - active}"
  if active == 0
    puts "no winner"; break
  end
  win = cont.find { |c| cnt[c] * 2 > active }
  if win
    puts "winner #{win}"; break
  end
  tied = cont.select { |c| cnt[c] == cnt.values.min }
  (round - 2).downto(0) do |k|
    break if tied.size == 1
    mn = tied.map { |c| hist[k][c] }.min
    tied = tied.select { |c| hist[k][c] == mn }
  end
  el = tied.max_by(&:b)
  cont.delete(el)
  puts "  eliminated #{el}"
end
