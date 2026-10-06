def money(c) = format("%d.%02d", c / 100, c % 100)
today = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
nloans = Hash.new(0)
ARGS = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }
MEM = /\A[a-z]{1,12}\z/
BK = /\A[A-Z][A-Z0-9]{0,7}\z/
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = ->(m) { puts "line #{n}: error: #{m}" }
  ref = ->(m) { puts "line #{n}: refused: #{m}" }
  unless f[0] =~ /\A\d+\z/ && f[0].to_i <= 100000
    err.("bad day"); next
  end
  d = f[0].to_i
  if d < today
    err.("day goes backwards"); next
  end
  today = d
  cmd = f[1]
  unless ARGS.key?(cmd)
    err.("unknown command"); next
  end
  if f.size != ARGS[cmd]
    err.("wrong field count"); next
  end
  case cmd
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    (err.("bad member"); next) unless m =~ MEM
    (err.("bad book"); next) unless b =~ BK
    if cmd == "CHECKOUT"
      if loans[b] then ref.("#{b} is on loan"); next end
      if holds[b] && holds[b] != m then ref.("#{b} is held for #{holds[b]}"); next end
      if loans.any? { |_, (mm, due)| mm == m && due < today } then ref.("#{m} has overdue books"); next end
      if nloans[m] >= 3 then ref.("#{m} has 3 loans"); next end
      if owed[m] >= 1000 then ref.("#{m} owes #{money(owed[m])}"); next end
      loans[b] = [m, today + 14]
      nloans[m] += 1
      holds.delete(b) if holds[b] == m
      seen[m] = true
      puts "#{m} borrowed #{b}, due day #{today + 14}"
    else
      if loans[b] && loans[b][0] == m then ref.("#{m} already has #{b}"); next end
      if holds[b] == m || queues[b].include?(m) then ref.("#{m} already reserved #{b}"); next end
      if !loans[b] && !holds[b] then ref.("#{b} is available"); next end
      queues[b] << m
      seen[m] = true
      puts "reserved #{b} for #{m} (position #{queues[b].size})"
    end
  when "RETURN"
    b = f[2]
    (err.("bad book"); next) unless b =~ BK
    unless loans[b] then ref.("#{b} is not on loan"); next end
    m, due = loans.delete(b)
    nloans[m] -= 1
    late = today - due
    if late > 0
      fine = [25 * late, 500].min
      owed[m] += fine
      puts "#{m} returned #{b}, #{late} days late, fine #{money(fine)}"
    else
      puts "#{m} returned #{b}"
    end
    unless queues[b].empty?
      holds[b] = queues[b].shift
      puts "#{b} held for #{holds[b]}"
    end
  when "PAY"
    m, a = f[2], f[3]
    (err.("bad member"); next) unless m =~ MEM
    unless a =~ /\A(\d+)(?:\.(\d{1,2}))?\z/ && (c = $1.to_i * 100 + ($2 ? ($2.ljust(2, "0")).to_i : 0)) > 0
      err.("bad amount"); next
    end
    if c > owed[m] then ref.("#{m} owes only #{money(owed[m])}"); next end
    owed[m] -= c
    puts "#{m} paid #{money(c)}, owes #{money(owed[m])}"
  end
end
puts format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each { |m| puts format("%-12s %5d %8s", m, nloans[m], money(owed[m])) }
puts "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.map { |b, (m, due)| [due, b, m] }.sort
if od.empty? then puts "  none"
else od.each { |due, b, m| puts "  #{b} #{m} due #{due} (#{today - due} days)" } end
