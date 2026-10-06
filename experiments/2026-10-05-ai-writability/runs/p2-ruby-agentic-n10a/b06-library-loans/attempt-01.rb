def money(c)
  format("%d.%02d", c / 100, c % 100)
end

def cents(s)
  w, f = s.split(".")
  w.to_i * 100 + (f ? (f + "0")[0, 2].to_i : 0)
end

FIELDS = {"CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4}
loans = {}   # book => {member:, due:}
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owed = Hash.new(0)
seen = {}
today = 0

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  e = lambda { |m| puts "line #{n}: error: #{m}" }
  r = lambda { |m| puts "line #{n}: refused: #{m}" }
  if f[0] !~ /\A\d+\z/ || f[0].to_i > 100_000
    e.call("bad day"); next
  end
  d = f[0].to_i
  if d < today
    e.call("day goes backwards"); next
  end
  today = d
  cmd = f[1]
  unless FIELDS.key?(cmd)
    e.call("unknown command"); next
  end
  if f.size != FIELDS[cmd]
    e.call("wrong field count"); next
  end
  mem = book = amt = nil
  case cmd
  when "CHECKOUT", "RESERVE" then mem, book = f[2], f[3]
  when "RETURN" then book = f[2]
  when "PAY" then mem, amt = f[2], f[3]
  end
  if mem && mem !~ /\A[a-z]{1,12}\z/ then e.call("bad member"); next end
  if book && book !~ /\A[A-Z][A-Z0-9]{0,7}\z/ then e.call("bad book"); next end
  if amt && (amt !~ /\A\d+(\.\d{1,2})?\z/ || cents(amt) == 0) then e.call("bad amount"); next end

  case cmd
  when "CHECKOUT"
    mine = loans.select { |_, l| l[:member] == mem }
    if loans.key?(book) then r.call("#{book} is on loan")
    elsif holds.key?(book) && holds[book] != mem then r.call("#{book} is held for #{holds[book]}")
    elsif mine.values.any? { |l| l[:due] < today } then r.call("#{mem} has overdue books")
    elsif mine.size >= 3 then r.call("#{mem} has 3 loans")
    elsif owed[mem] >= 1000 then r.call("#{mem} owes #{money(owed[mem])}")
    else
      loans[book] = {member: mem, due: today + 14}
      holds.delete(book) if holds[book] == mem
      seen[mem] = true
      puts "#{mem} borrowed #{book}, due day #{today + 14}"
    end
  when "RETURN"
    l = loans[book]
    if l.nil?
      r.call("#{book} is not on loan")
    else
      loans.delete(book)
      late = today - l[:due]
      if late > 0
        fine = [late * 25, 500].min
        owed[l[:member]] += fine
        puts "#{l[:member]} returned #{book}, #{late} days late, fine #{money(fine)}"
      else
        puts "#{l[:member]} returned #{book}"
      end
      unless queues[book].empty?
        m = queues[book].shift
        holds[book] = m
        puts "#{book} held for #{m}"
      end
    end
  when "RESERVE"
    if loans[book] && loans[book][:member] == mem then r.call("#{mem} already has #{book}")
    elsif holds[book] == mem || queues[book].include?(mem) then r.call("#{mem} already reserved #{book}")
    elsif !loans.key?(book) && !holds.key?(book) then r.call("#{book} is available")
    else
      queues[book] << mem
      seen[mem] = true
      puts "reserved #{book} for #{mem} (position #{queues[book].size})"
    end
  when "PAY"
    c = cents(amt)
    if c > owed[mem]
      r.call("#{mem} owes only #{money(owed[mem])}")
    else
      owed[mem] -= c
      puts "#{mem} paid #{money(c)}, owes #{money(owed[mem])}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort_by(&:b).each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, l| l[:member] == m }, money(owed[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, l| l[:due] < today }.sort_by { |b, l| [l[:due], b.b] }
if od.empty?
  puts "  none"
else
  od.each { |b, l| puts "  #{b} #{l[:member]} due #{l[:due]} (#{today - l[:due]} days)" }
end
