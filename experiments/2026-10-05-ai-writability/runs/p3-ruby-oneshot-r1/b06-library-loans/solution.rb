def money(c)
  format("%d.%02d", c / 100, c % 100)
end

cur = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owes = Hash.new(0)
seen = {}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  day_s = f[0]
  unless day_s =~ /\A\d+\z/ && day_s.to_i <= 100000
    out << "line #{n}: error: bad day"
    next
  end
  day = day_s.to_i
  if day < cur
    out << "line #{n}: error: day goes backwards"
    next
  end
  cur = day
  cmd = f[1]
  need = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }[cmd]
  if need.nil?
    out << "line #{n}: error: unknown command"
    next
  end
  if f.size != need
    out << "line #{n}: error: wrong field count"
    next
  end
  mem_ok = ->(s) { s =~ /\A[a-z]{1,12}\z/ }
  book_ok = ->(s) { s =~ /\A[A-Z][A-Z0-9]{0,7}\z/ }
  case cmd
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    unless mem_ok.(m)
      out << "line #{n}: error: bad member"
      next
    end
    unless book_ok.(b)
      out << "line #{n}: error: bad book"
      next
    end
    if cmd == "CHECKOUT"
      msg = nil
      if loans[b]
        msg = "#{b} is on loan"
      elsif holds[b] && holds[b] != m
        msg = "#{b} is held for #{holds[b]}"
      elsif loans.any? { |_, (lm, due)| lm == m && due < cur }
        msg = "#{m} has overdue books"
      elsif loans.count { |_, (lm, _)| lm == m } >= 3
        msg = "#{m} has 3 loans"
      elsif owes[m] >= 1000
        msg = "#{m} owes #{money(owes[m])}"
      end
      if msg
        out << "line #{n}: refused: #{msg}"
      else
        loans[b] = [m, cur + 14]
        holds.delete(b) if holds[b] == m
        seen[m] = true
        out << "#{m} borrowed #{b}, due day #{cur + 14}"
      end
    else
      msg = nil
      if loans[b] && loans[b][0] == m
        msg = "#{m} already has #{b}"
      elsif holds[b] == m || queues[b].include?(m)
        msg = "#{m} already reserved #{b}"
      elsif !loans[b] && !holds[b]
        msg = "#{b} is available"
      end
      if msg
        out << "line #{n}: refused: #{msg}"
      else
        queues[b] << m
        seen[m] = true
        out << "reserved #{b} for #{m} (position #{queues[b].size})"
      end
    end
  when "RETURN"
    b = f[2]
    unless book_ok.(b)
      out << "line #{n}: error: bad book"
      next
    end
    unless loans[b]
      out << "line #{n}: refused: #{b} is not on loan"
      next
    end
    m, due = loans.delete(b)
    late = cur - due
    if late > 0
      fine = [25 * late, 500].min
      owes[m] += fine
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
    unless mem_ok.(m)
      out << "line #{n}: error: bad member"
      next
    end
    unless a =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
      out << "line #{n}: error: bad amount"
      next
    end
    cents = $1.to_i * 100 + ($2 ? ($2.ljust(2, "0")).to_i : 0)
    if cents <= 0
      out << "line #{n}: error: bad amount"
      next
    end
    if cents > owes[m]
      out << "line #{n}: refused: #{m} owes only #{money(owes[m])}"
    else
      owes[m] -= cents
      out << "#{m} paid #{money(cents)}, owes #{money(owes[m])}"
    end
  end
end

out << format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  cnt = loans.count { |_, (lm, _)| lm == m }
  out << format("%-12s %5d %8s", m, cnt, money(owes[m]))
end
out << "overdue on day #{cur}:"
od = loans.select { |_, (_, due)| due < cur }.sort_by { |b, (_, due)| [due, b] }
if od.empty?
  out << "  none"
else
  od.each { |b, (m, due)| out << "  #{b} #{m} due #{due} (#{cur - due} days)" }
end
puts out
