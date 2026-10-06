def money(c) = format("%d.%02d", c / 100, c % 100)

today = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
FIELDS = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  day = f[0]
  unless day.match?(/\A\d+\z/) && day.to_i <= 100000
    puts "line #{n}: error: bad day"
    next
  end
  d = day.to_i
  if d < today
    puts "line #{n}: error: day goes backwards"
    next
  end
  today = d
  cmd = f[1]
  unless FIELDS.key?(cmd)
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != FIELDS[cmd]
    puts "line #{n}: error: wrong field count"
    next
  end
  member = book = amount = nil
  case cmd
  when "CHECKOUT", "RESERVE"
    member, book = f[2], f[3]
  when "RETURN"
    book = f[2]
  when "PAY"
    member, amount = f[2], f[3]
  end
  if member && !member.match?(/\A[a-z]{1,12}\z/)
    puts "line #{n}: error: bad member"
    next
  end
  if book && !book.match?(/\A[A-Z][A-Z0-9]{0,7}\z/)
    puts "line #{n}: error: bad book"
    next
  end
  if amount
    m = amount.match(/\A(\d+)(?:\.(\d{1,2}))?\z/)
    cents = m ? m[1].to_i * 100 + (m[2] ? m[2].ljust(2, "0").to_i : 0) : 0
    if cents <= 0
      puts "line #{n}: error: bad amount"
      next
    end
  end

  case cmd
  when "CHECKOUT"
    if loans.key?(book)
      puts "line #{n}: refused: #{book} is on loan"
    elsif holds[book] && holds[book] != member
      puts "line #{n}: refused: #{book} is held for #{holds[book]}"
    elsif loans.any? { |_, (m, due)| m == member && due < today }
      puts "line #{n}: refused: #{member} has overdue books"
    elsif loans.count { |_, (m, _)| m == member } >= 3
      puts "line #{n}: refused: #{member} has 3 loans"
    elsif owed[member] >= 1000
      puts "line #{n}: refused: #{member} owes #{money(owed[member])}"
    else
      loans[book] = [member, today + 14]
      holds.delete(book) if holds[book] == member
      seen[member] = true
      puts "#{member} borrowed #{book}, due day #{today + 14}"
    end
  when "RETURN"
    unless loans.key?(book)
      puts "line #{n}: refused: #{book} is not on loan"
      next
    end
    m, due = loans.delete(book)
    late = today - due
    if late > 0
      fine = [late * 25, 500].min
      owed[m] += fine
      puts "#{m} returned #{book}, #{late} days late, fine #{money(fine)}"
    else
      puts "#{m} returned #{book}"
    end
    q = queues[book]
    unless q.empty?
      nxt = q.shift
      holds[book] = nxt
      puts "#{book} held for #{nxt}"
    end
  when "RESERVE"
    if loans[book] && loans[book][0] == member
      puts "line #{n}: refused: #{member} already has #{book}"
    elsif holds[book] == member || queues[book].include?(member)
      puts "line #{n}: refused: #{member} already reserved #{book}"
    elsif !loans.key?(book) && !holds.key?(book)
      puts "line #{n}: refused: #{book} is available"
    else
      queues[book] << member
      seen[member] = true
      puts "reserved #{book} for #{member} (position #{queues[book].size})"
    end
  when "PAY"
    if cents > owed[member]
      puts "line #{n}: refused: #{member} owes only #{money(owed[member])}"
    else
      owed[member] -= cents
      puts "#{member} paid #{money(cents)}, owes #{money(owed[member])}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, (lm, _)| lm == m }, money(owed[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.sort_by { |b, (_, due)| [due, b] }
if od.empty?
  puts "  none"
else
  od.each { |b, (m, due)| puts "  #{b} #{m} due #{due} (#{today - due} days)" }
end
