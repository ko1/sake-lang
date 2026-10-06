def money(c) = format("%d.%02d", c / 100, c % 100)

def cents(s)
  a, b = s.split(".")
  a.to_i * 100 + (b ? (b.size == 1 ? b.to_i * 10 : b.to_i) : 0)
end

MEM = /\A[a-z]{1,12}\z/
BOOK = /\A[A-Z][A-Z0-9]{0,7}\z/
AMT = /\A\d+(\.\d{1,2})?\z/
COUNTS = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }.freeze

today = 0
loans = {}  # book => [member, due]
holds = {}  # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  if f[0] !~ /\A\d+\z/ || f[0].to_i > 100_000
    puts "line #{no}: error: bad day"
    next
  end
  day = f[0].to_i
  if day < today
    puts "line #{no}: error: day goes backwards"
    next
  end
  today = day
  cmd = f[1]
  unless COUNTS.key?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != COUNTS[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  err = nil
  case cmd
  when "CHECKOUT", "RESERVE"
    err = "bad member" if f[2] !~ MEM
    err ||= "bad book" if f[3] !~ BOOK
  when "RETURN"
    err = "bad book" if f[2] !~ BOOK
  when "PAY"
    err = "bad member" if f[2] !~ MEM
    err ||= "bad amount" if f[3] !~ AMT || cents(f[3]) == 0
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "CHECKOUT"
    m, b = f[2], f[3]
    mine = loans.select { |_, l| l[0] == m }
    msg =
      if loans.key?(b) then "#{b} is on loan"
      elsif holds.key?(b) && holds[b] != m then "#{b} is held for #{holds[b]}"
      elsif mine.any? { |_, l| l[1] < today } then "#{m} has overdue books"
      elsif mine.size >= 3 then "#{m} has 3 loans"
      elsif owed[m] >= 1000 then "#{m} owes #{money(owed[m])}"
      end
    if msg
      puts "line #{no}: refused: #{msg}"
    else
      loans[b] = [m, today + 14]
      holds.delete(b) if holds[b] == m
      seen[m] = true
      puts "#{m} borrowed #{b}, due day #{today + 14}"
    end
  when "RETURN"
    b = f[2]
    unless loans.key?(b)
      puts "line #{no}: refused: #{b} is not on loan"
      next
    end
    m, due = loans.delete(b)
    late = today - due
    if late > 0
      fine = [late * 25, 500].min
      owed[m] += fine
      puts "#{m} returned #{b}, #{late} days late, fine #{money(fine)}"
    else
      puts "#{m} returned #{b}"
    end
    if (nxt = queues[b].shift)
      holds[b] = nxt
      puts "#{b} held for #{nxt}"
    end
  when "RESERVE"
    m, b = f[2], f[3]
    msg =
      if loans.key?(b) && loans[b][0] == m then "#{m} already has #{b}"
      elsif holds[b] == m || queues[b].include?(m) then "#{m} already reserved #{b}"
      elsif !loans.key?(b) && !holds.key?(b) then "#{b} is available"
      end
    if msg
      puts "line #{no}: refused: #{msg}"
    else
      queues[b] << m
      seen[m] = true
      puts "reserved #{b} for #{m} (position #{queues[b].size})"
    end
  when "PAY"
    m = f[2]
    amt = cents(f[3])
    if amt > owed[m]
      puts "line #{no}: refused: #{m} owes only #{money(owed[m])}"
    else
      owed[m] -= amt
      puts "#{m} paid #{money(amt)}, owes #{money(owed[m])}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort_by(&:b).each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, l| l[0] == m }, money(owed[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, l| l[1] < today }.sort_by { |b, l| [l[1], b.b] }
if od.empty?
  puts "  none"
else
  od.each { |b, l| puts "  #{b} #{l[0]} due #{l[1]} (#{today - l[1]} days)" }
end
