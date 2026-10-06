def money(c) = format("%d.%02d", c / 100, c % 100)

loans = {}   # book => [member, due]
holds = {}   # book => member
queue = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
members = {}
today = 0
n = 0
$stdin.each_line do |raw|
  n += 1
  line = raw.strip
  next if line.empty?
  f = line.split(/ +/)
  pre = "line #{n}: "
  day = f[0]
  unless day =~ /\A\d+\z/ && day.to_i <= 100000
    puts "#{pre}error: bad day"
    next
  end
  d = day.to_i
  if d < today
    puts "#{pre}error: day goes backwards"
    next
  end
  today = d
  cmd = f[1]
  need = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }[cmd]
  if need.nil?
    puts "#{pre}error: unknown command"
    next
  end
  if f.size != need
    puts "#{pre}error: wrong field count"
    next
  end
  member = book = amt = nil
  case cmd
  when "CHECKOUT", "RESERVE"
    member, book = f[2], f[3]
  when "RETURN"
    book = f[2]
  when "PAY"
    member, amt = f[2], f[3]
  end
  if member && member !~ /\A[a-z]{1,12}\z/
    puts "#{pre}error: bad member"
    next
  end
  if book && book !~ /\A[A-Z][A-Z0-9]{0,7}\z/
    puts "#{pre}error: bad book"
    next
  end
  if amt
    if amt =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
      cents = $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
    else
      cents = 0
    end
    if cents <= 0
      puts "#{pre}error: bad amount"
      next
    end
  end
  case cmd
  when "CHECKOUT"
    if loans[book]
      puts "#{pre}refused: #{book} is on loan"
    elsif holds[book] && holds[book] != member
      puts "#{pre}refused: #{book} is held for #{holds[book]}"
    elsif loans.any? { |_, (m, due)| m == member && due < today }
      puts "#{pre}refused: #{member} has overdue books"
    elsif loans.count { |_, (m, _)| m == member } >= 3
      puts "#{pre}refused: #{member} has 3 loans"
    elsif owed[member] >= 1000
      puts "#{pre}refused: #{member} owes #{money(owed[member])}"
    else
      loans[book] = [member, today + 14]
      holds.delete(book) if holds[book] == member
      members[member] = true
      puts "#{member} borrowed #{book}, due day #{today + 14}"
    end
  when "RETURN"
    l = loans[book]
    if l.nil?
      puts "#{pre}refused: #{book} is not on loan"
    else
      m, due = l
      late = today - due
      if late > 0
        fine = [25 * late, 500].min
        owed[m] += fine
        puts "#{m} returned #{book}, #{late} days late, fine #{money(fine)}"
      else
        puts "#{m} returned #{book}"
      end
      loans.delete(book)
      unless queue[book].empty?
        w = queue[book].shift
        holds[book] = w
        puts "#{book} held for #{w}"
      end
    end
  when "RESERVE"
    if loans[book] && loans[book][0] == member
      puts "#{pre}refused: #{member} already has #{book}"
    elsif holds[book] == member || queue[book].include?(member)
      puts "#{pre}refused: #{member} already reserved #{book}"
    elsif !loans[book] && !holds[book]
      puts "#{pre}refused: #{book} is available"
    else
      queue[book] << member
      members[member] = true
      puts "reserved #{book} for #{member} (position #{queue[book].size})"
    end
  when "PAY"
    if cents > owed[member]
      puts "#{pre}refused: #{member} owes only #{money(owed[member])}"
    else
      owed[member] -= cents
      puts "#{member} paid #{money(cents)}, owes #{money(owed[member])}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
members.keys.sort.each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, (x, _)| x == m }, money(owed[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.sort_by { |b, (_, due)| [due, b] }
if od.empty?
  puts "  none"
else
  od.each { |b, (m, due)| puts "  #{b} #{m} due #{due} (#{today - due} days)" }
end
