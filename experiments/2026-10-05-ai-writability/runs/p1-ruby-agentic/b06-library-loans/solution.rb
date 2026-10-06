def money(c) = format("%d.%02d", c / 100, c % 100)

today = 0
loans = {}    # book => [member, due]
holds = {}    # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
members = {}

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  d = f[0]
  if d !~ /\A\d+\z/ || d.to_i > 100000
    puts "line #{n}: error: bad day"; next
  end
  d = d.to_i
  if d < today
    puts "line #{n}: error: day goes backwards"; next
  end
  today = d
  cmd = f[1]
  counts = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }
  unless counts[cmd]
    puts "line #{n}: error: unknown command"; next
  end
  if f.size != counts[cmd]
    puts "line #{n}: error: wrong field count"; next
  end
  mem_ok = ->(m) { m =~ /\A[a-z]{1,12}\z/ }
  book_ok = ->(b) { b =~ /\A[A-Z][A-Z0-9]{0,7}\z/ }
  err = nil
  case cmd
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    err = "bad member" unless mem_ok[m]
    err ||= "bad book" unless book_ok[b]
  when "RETURN"
    b = f[2]
    err = "bad book" unless book_ok[b]
  when "PAY"
    m = f[2]
    err = "bad member" unless mem_ok[m]
    if !err
      if f[3] =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
        amt = $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
        err = "bad amount" if amt <= 0
      else
        err = "bad amount"
      end
    end
  end
  if err
    puts "line #{n}: error: #{err}"; next
  end

  case cmd
  when "CHECKOUT"
    ref = nil
    if loans[b]
      ref = "#{b} is on loan"
    elsif holds[b] && holds[b] != m
      ref = "#{b} is held for #{holds[b]}"
    elsif loans.any? { |_, (lm, due)| lm == m && due < today }
      ref = "#{m} has overdue books"
    elsif loans.count { |_, (lm, _)| lm == m } >= 3
      ref = "#{m} has 3 loans"
    elsif owed[m] >= 1000
      ref = "#{m} owes #{money(owed[m])}"
    end
    if ref
      puts "line #{n}: refused: #{ref}"
    else
      loans[b] = [m, today + 14]
      holds.delete(b) if holds[b] == m
      members[m] = true
      puts "#{m} borrowed #{b}, due day #{today + 14}"
    end
  when "RETURN"
    unless loans[b]
      puts "line #{n}: refused: #{b} is not on loan"; next
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
      nm = queues[b].shift
      holds[b] = nm
      puts "#{b} held for #{nm}"
    end
  when "RESERVE"
    ref = nil
    if loans[b] && loans[b][0] == m
      ref = "#{m} already has #{b}"
    elsif holds[b] == m || queues[b].include?(m)
      ref = "#{m} already reserved #{b}"
    elsif !loans[b] && !holds[b]
      ref = "#{b} is available"
    end
    if ref
      puts "line #{n}: refused: #{ref}"
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
