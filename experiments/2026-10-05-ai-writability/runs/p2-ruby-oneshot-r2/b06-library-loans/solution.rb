def money(c) = format("%d.%02d", c / 100, c % 100)

today = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
members = {}
ARGC = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  d = f[0]
  unless d.match?(/\A\d+\z/) && d.to_i <= 100000
    puts "line #{n}: error: bad day"
    next
  end
  d = d.to_i
  if d < today
    puts "line #{n}: error: day goes backwards"
    next
  end
  today = d
  cmd = f[1]
  unless ARGC.key?(cmd)
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != ARGC[cmd]
    puts "line #{n}: error: wrong field count"
    next
  end
  mem_ok = ->(s) { s.match?(/\A[a-z]{1,12}\z/) }
  book_ok = ->(s) { s.match?(/\A[A-Z][A-Z0-9]{0,7}\z/) }
  case cmd
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    unless mem_ok.(m)
      puts "line #{n}: error: bad member"
      next
    end
    unless book_ok.(b)
      puts "line #{n}: error: bad book"
      next
    end
  when "RETURN"
    b = f[2]
    unless book_ok.(b)
      puts "line #{n}: error: bad book"
      next
    end
  when "PAY"
    m = f[2]
    unless mem_ok.(m)
      puts "line #{n}: error: bad member"
      next
    end
    a = f[3]
    unless a.match?(/\A\d+(\.\d{1,2})?\z/)
      puts "line #{n}: error: bad amount"
      next
    end
    ip, fp = a.split(".")
    amt = ip.to_i * 100 + (fp ? fp.ljust(2, "0").to_i : 0)
    if amt <= 0
      puts "line #{n}: error: bad amount"
      next
    end
  end

  case cmd
  when "CHECKOUT"
    msg =
      if loans.key?(b) then "#{b} is on loan"
      elsif holds.key?(b) && holds[b] != m then "#{b} is held for #{holds[b]}"
      elsif loans.any? { |_, (lm, due)| lm == m && due < today } then "#{m} has overdue books"
      elsif loans.count { |_, (lm, _)| lm == m } >= 3 then "#{m} has 3 loans"
      elsif owed[m] >= 1000 then "#{m} owes #{money(owed[m])}"
      end
    if msg
      puts "line #{n}: refused: #{msg}"
    else
      loans[b] = [m, today + 14]
      holds.delete(b) if holds[b] == m
      members[m] = true
      puts "#{m} borrowed #{b}, due day #{today + 14}"
    end
  when "RETURN"
    unless loans.key?(b)
      puts "line #{n}: refused: #{b} is not on loan"
      next
    end
    bm, due = loans.delete(b)
    late = today - due
    if late > 0
      fine = [late * 25, 500].min
      owed[bm] += fine
      puts "#{bm} returned #{b}, #{late} days late, fine #{money(fine)}"
    else
      puts "#{bm} returned #{b}"
    end
    unless queues[b].empty?
      w = queues[b].shift
      holds[b] = w
      puts "#{b} held for #{w}"
    end
  when "RESERVE"
    msg =
      if loans.key?(b) && loans[b][0] == m then "#{m} already has #{b}"
      elsif holds[b] == m || queues[b].include?(m) then "#{m} already reserved #{b}"
      elsif !loans.key?(b) && !holds.key?(b) then "#{b} is available"
      end
    if msg
      puts "line #{n}: refused: #{msg}"
    else
      queues[b] << m
      members[m] = true
      puts "reserved #{b} for #{m} (position #{queues[b].size})"
    end
  when "PAY"
    if amt > owed[m]
      puts "line #{n}: refused: #{m} owes only #{money(owed[m])}"
    else
      owed[m] -= amt
      puts "#{m} paid #{money(amt)}, owes #{money(owed[m])}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
members.keys.sort.each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, (lm, _)| lm == m }, money(owed[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.sort_by { |b, (_, due)| [due, b] }
if od.empty?
  puts "  none"
else
  od.each { |b, (m, due)| puts "  #{b} #{m} due #{due} (#{today - due} days)" }
end
