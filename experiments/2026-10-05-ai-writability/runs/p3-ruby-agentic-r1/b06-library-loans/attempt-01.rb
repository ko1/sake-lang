def money(c) = format("%d.%02d", c / 100, c % 100)

today = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty?
  f = line.split(" ")
  err = ->(m) { out << "line #{n}: error: #{m}" }
  ref = ->(m) { out << "line #{n}: refused: #{m}" }
  unless f[0] =~ /\A\d+\z/ && f[0].to_i <= 100000
    err.("bad day"); next
  end
  day = f[0].to_i
  if day < today
    err.("day goes backwards"); next
  end
  today = day
  cmd = f[1]
  need = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }[cmd]
  unless need
    err.("unknown command"); next
  end
  if f.size != need
    err.("wrong field count"); next
  end
  mem_ok = ->(m) { m =~ /\A[a-z]{1,12}\z/ }
  book_ok = ->(b) { b =~ /\A[A-Z][A-Z0-9]{0,7}\z/ }
  case cmd
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    (err.("bad member"); next) unless mem_ok.(m)
    (err.("bad book"); next) unless book_ok.(b)
    if cmd == "CHECKOUT"
      if loans[b] then ref.("#{b} is on loan"); next end
      if holds[b] && holds[b] != m then ref.("#{b} is held for #{holds[b]}"); next end
      mine = loans.select { |_, v| v[0] == m }
      if mine.any? { |_, v| v[1] < today } then ref.("#{m} has overdue books"); next end
      if mine.size >= 3 then ref.("#{m} has 3 loans"); next end
      if owed[m] >= 1000 then ref.("#{m} owes #{money(owed[m])}"); next end
      loans[b] = [m, today + 14]
      holds.delete(b) if holds[b] == m
      seen[m] = true
      out << "#{m} borrowed #{b}, due day #{today + 14}"
    else
      if loans[b] && loans[b][0] == m then ref.("#{m} already has #{b}"); next end
      if holds[b] == m || queues[b].include?(m) then ref.("#{m} already reserved #{b}"); next end
      if !loans[b] && !holds[b] then ref.("#{b} is available"); next end
      queues[b] << m
      seen[m] = true
      out << "reserved #{b} for #{m} (position #{queues[b].size})"
    end
  when "RETURN"
    b = f[2]
    (err.("bad book"); next) unless book_ok.(b)
    unless loans[b] then ref.("#{b} is not on loan"); next end
    m, due = loans.delete(b)
    late = today - due
    if late > 0
      fine = [late * 25, 500].min
      owed[m] += fine
      out << "#{m} returned #{b}, #{late} days late, fine #{money(fine)}"
    else
      out << "#{m} returned #{b}"
    end
    if (nx = queues[b].shift)
      holds[b] = nx
      out << "#{b} held for #{nx}"
    end
  when "PAY"
    m, a = f[2], f[3]
    (err.("bad member"); next) unless mem_ok.(m)
    unless a =~ /\A(\d+)(?:\.(\d{1,2}))?\z/ && (c = $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i) > 0
      err.("bad amount"); next
    end
    if c > owed[m] then ref.("#{m} owes only #{money(owed[m])}"); next end
    owed[m] -= c
    out << "#{m} paid #{money(c)}, owes #{money(owed[m])}"
  end
end

out << format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  out << format("%-12s %5d %8s", m, loans.count { |_, v| v[0] == m }, money(owed[m]))
end
out << "overdue on day #{today}:"
od = loans.select { |_, v| v[1] < today }.sort_by { |b, v| [v[1], b] }
if od.empty?
  out << "  none"
else
  od.each { |b, (m, d)| out << "  #{b} #{m} due #{d} (#{today - d} days)" }
end
puts out
