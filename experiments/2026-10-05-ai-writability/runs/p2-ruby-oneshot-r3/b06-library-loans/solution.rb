def money(c) = format("%d.%02d", c / 100, c % 100)

current = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty?
  f = line.split
  unless f[0] =~ /\A\d+\z/ && f[0].to_i <= 100000
    out << "line #{n}: error: bad day"
    next
  end
  day = f[0].to_i
  if day < current
    out << "line #{n}: error: day goes backwards"
    next
  end
  current = day
  cmd = f[1]
  counts = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }
  unless counts.key?(cmd)
    out << "line #{n}: error: unknown command"
    next
  end
  if f.size != counts[cmd]
    out << "line #{n}: error: wrong field count"
    next
  end
  member = nil
  book = nil
  amount = nil
  case cmd
  when "CHECKOUT", "RESERVE"
    member, book = f[2], f[3]
  when "RETURN"
    book = f[2]
  when "PAY"
    member = f[2]
    amount = f[3]
  end
  if member && member !~ /\A[a-z]{1,12}\z/
    out << "line #{n}: error: bad member"
    next
  end
  if book && book !~ /\A[A-Z][A-Z0-9]{0,7}\z/
    out << "line #{n}: error: bad book"
    next
  end
  if amount
    cents = nil
    if amount =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
      cents = $1.to_i * 100 + ($2 ? ($2 + "0")[0, 2].to_i : 0)
    end
    if cents.nil? || cents <= 0
      out << "line #{n}: error: bad amount"
      next
    end
    amount = cents
  end

  case cmd
  when "CHECKOUT"
    if loans.key?(book)
      out << "line #{n}: refused: #{book} is on loan"
    elsif holds[book] && holds[book] != member
      out << "line #{n}: refused: #{book} is held for #{holds[book]}"
    elsif loans.any? { |_, (m, due)| m == member && due < current }
      out << "line #{n}: refused: #{member} has overdue books"
    elsif loans.count { |_, (m, _)| m == member } >= 3
      out << "line #{n}: refused: #{member} has 3 loans"
    elsif owed[member] >= 1000
      out << "line #{n}: refused: #{member} owes #{money(owed[member])}"
    else
      loans[book] = [member, current + 14]
      holds.delete(book) if holds[book] == member
      seen[member] = true
      out << "#{member} borrowed #{book}, due day #{current + 14}"
    end
  when "RETURN"
    if !loans.key?(book)
      out << "line #{n}: refused: #{book} is not on loan"
    else
      m, due = loans.delete(book)
      late = current - due
      if late > 0
        fine = [late * 25, 500].min
        owed[m] += fine
        out << "#{m} returned #{book}, #{late} days late, fine #{money(fine)}"
      else
        out << "#{m} returned #{book}"
      end
      unless queues[book].empty?
        nxt = queues[book].shift
        holds[book] = nxt
        out << "#{book} held for #{nxt}"
      end
    end
  when "RESERVE"
    if loans[book] && loans[book][0] == member
      out << "line #{n}: refused: #{member} already has #{book}"
    elsif holds[book] == member || queues[book].include?(member)
      out << "line #{n}: refused: #{member} already reserved #{book}"
    elsif !loans.key?(book) && !holds.key?(book)
      out << "line #{n}: refused: #{book} is available"
    else
      queues[book] << member
      seen[member] = true
      out << "reserved #{book} for #{member} (position #{queues[book].size})"
    end
  when "PAY"
    if amount > owed[member]
      out << "line #{n}: refused: #{member} owes only #{money(owed[member])}"
    else
      owed[member] -= amount
      out << "#{member} paid #{money(amount)}, owes #{money(owed[member])}"
    end
  end
end

out << format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  cnt = loans.count { |_, (lm, _)| lm == m }
  out << format("%-12s %5d %8s", m, cnt, money(owed[m]))
end
out << "overdue on day #{current}:"
od = loans.select { |_, (_, due)| due < current }.map { |b, (m, due)| [due, b, m] }.sort
if od.empty?
  out << "  none"
else
  od.each { |due, b, m| out << "  #{b} #{m} due #{due} (#{current - due} days)" }
end
puts out
