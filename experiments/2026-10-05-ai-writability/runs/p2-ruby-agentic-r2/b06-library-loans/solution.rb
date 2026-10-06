def money(c) = format("%d.%02d", c / 100, c % 100)

loans = {}   # book => [member, due]
holds = {}   # book => member
queues = Hash.new { |h, k| h[k] = [] }
owes = Hash.new(0)
seen = {}
today = 0
ARGS = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  next if line.strip.empty?
  f = line.strip.split(/ +/)
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
  when "CHECKOUT", "RESERVE", "PAY"
    m = f[2]
    unless m =~ /\A[a-z]{1,12}\z/
      err.("bad member"); next
    end
    if cmd == "PAY"
      a = f[3]
      unless a =~ /\A(\d+)(?:\.(\d{1,2}))?\z/ && ($1.to_i * 100 + ($2 || "").ljust(2, "0").to_i) > 0
        err.("bad amount"); next
      end
      amt = $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
      if amt > owes[m]
        ref.("#{m} owes only #{money(owes[m])}")
      else
        owes[m] -= amt
        puts "#{m} paid #{money(amt)}, owes #{money(owes[m])}"
      end
      next
    end
    b = f[3]
    unless b =~ /\A[A-Z][A-Z0-9]{0,7}\z/
      err.("bad book"); next
    end
    if cmd == "CHECKOUT"
      if loans.key?(b) then ref.("#{b} is on loan")
      elsif holds[b] && holds[b] != m then ref.("#{b} is held for #{holds[b]}")
      elsif loans.any? { |_, (mm, due)| mm == m && due < today } then ref.("#{m} has overdue books")
      elsif loans.count { |_, (mm, _)| mm == m } >= 3 then ref.("#{m} has 3 loans")
      elsif owes[m] >= 1000 then ref.("#{m} owes #{money(owes[m])}")
      else
        holds.delete(b)
        loans[b] = [m, today + 14]
        seen[m] = true
        puts "#{m} borrowed #{b}, due day #{today + 14}"
      end
    else
      if loans[b] && loans[b][0] == m then ref.("#{m} already has #{b}")
      elsif holds[b] == m || queues[b].include?(m) then ref.("#{m} already reserved #{b}")
      elsif !loans.key?(b) && !holds.key?(b) then ref.("#{b} is available")
      else
        queues[b] << m
        seen[m] = true
        puts "reserved #{b} for #{m} (position #{queues[b].size})"
      end
    end
  when "RETURN"
    b = f[2]
    unless b =~ /\A[A-Z][A-Z0-9]{0,7}\z/
      err.("bad book"); next
    end
    unless loans.key?(b)
      ref.("#{b} is not on loan"); next
    end
    m, due = loans.delete(b)
    late = today - due
    if late > 0
      fine = [late * 25, 500].min
      owes[m] += fine
      puts "#{m} returned #{b}, #{late} days late, fine #{money(fine)}"
    else
      puts "#{m} returned #{b}"
    end
    if (w = queues[b].shift)
      holds[b] = w
      puts "#{b} held for #{w}"
    end
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
seen.keys.sort.each do |m|
  puts format("%-12s %5d %8s", m, loans.count { |_, (mm, _)| mm == m }, money(owes[m]))
end
puts "overdue on day #{today}:"
od = loans.select { |_, (_, due)| due < today }.map { |b, (m, due)| [due, b, m] }.sort
if od.empty?
  puts "  none"
else
  od.each { |due, b, m| puts "  #{b} #{m} due #{due} (#{today - due} days)" }
end
