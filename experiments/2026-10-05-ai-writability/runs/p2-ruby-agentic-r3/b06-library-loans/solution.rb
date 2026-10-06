def money(c) = format("%d.%02d", c / 100, c % 100)

today = 0
loans = {}   # book => [member, due]
holds = {}   # book => member
queue = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
out = []

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  err = ->(m) { out << "line #{n}: error: #{m}" }
  ref = ->(m) { out << "line #{n}: refused: #{m}" }
  d = f[0]
  unless d =~ /\A\d+\z/ && d.to_i <= 100000
    err.("bad day"); next
  end
  d = d.to_i
  if d < today
    err.("day goes backwards"); next
  end
  today = d
  cnt = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }[f[1]]
  unless cnt
    err.("unknown command"); next
  end
  if f.size != cnt
    err.("wrong field count"); next
  end
  mem_ok = ->(s) { s =~ /\A[a-z]{1,12}\z/ }
  book_ok = ->(s) { s =~ /\A[A-Z][A-Z0-9]{0,7}\z/ }
  case f[1]
  when "CHECKOUT", "RESERVE"
    m, b = f[2], f[3]
    (err.("bad member"); next) unless mem_ok.(m)
    (err.("bad book"); next) unless book_ok.(b)
    if f[1] == "CHECKOUT"
      if loans[b] then ref.("#{b} is on loan")
      elsif holds[b] && holds[b] != m then ref.("#{b} is held for #{holds[b]}")
      elsif loans.values.any? { |mm, dd| mm == m && dd < today } then ref.("#{m} has overdue books")
      elsif loans.values.count { |mm, _| mm == m } >= 3 then ref.("#{m} has 3 loans")
      elsif owed[m] >= 1000 then ref.("#{m} owes #{money(owed[m])}")
      else
        loans[b] = [m, today + 14]
        holds.delete(b) if holds[b] == m
        seen[m] = true
        out << "#{m} borrowed #{b}, due day #{today + 14}"
      end
    else
      if loans[b] && loans[b][0] == m then ref.("#{m} already has #{b}")
      elsif holds[b] == m || queue[b].include?(m) then ref.("#{m} already reserved #{b}")
      elsif !loans[b] && !holds[b] then ref.("#{b} is available")
      else
        queue[b] << m
        seen[m] = true
        out << "reserved #{b} for #{m} (position #{queue[b].size})"
      end
    end
  when "RETURN"
    b = f[2]
    (err.("bad book"); next) unless book_ok.(b)
    if !loans[b]
      ref.("#{b} is not on loan")
    else
      m, due = loans.delete(b)
      late = today - due
      if late > 0
        fine = [late * 25, 500].min
        owed[m] += fine
        out << "#{m} returned #{b}, #{late} days late, fine #{money(fine)}"
      else
        out << "#{m} returned #{b}"
      end
      if (nx = queue[b].shift)
        holds[b] = nx
        out << "#{b} held for #{nx}"
      end
    end
  when "PAY"
    m, a = f[2], f[3]
    (err.("bad member"); next) unless mem_ok.(m)
    unless a =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
      err.("bad amount"); next
    end
    c = $1.to_i * 100 + ($2 ? ($2.ljust(2, "0")).to_i : 0)
    (err.("bad amount"); next) if c <= 0
    if c > owed[m]
      ref.("#{m} owes only #{money(owed[m])}")
    else
      owed[m] -= c
      out << "#{m} paid #{money(c)}, owes #{money(owed[m])}"
    end
  end
end

out << format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  out << format("%-12s %5d %8s", m, loans.values.count { |mm, _| mm == m }, money(owed[m]))
end
out << "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.sort_by { |b, (_, due)| [due, b] }
if od.empty?
  out << "  none"
else
  od.each { |b, (m, due)| out << "  #{b} #{m} due #{due} (#{today - due} days)" }
end
puts out
