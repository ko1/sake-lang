class BadLine < StandardError; end
class Refused < StandardError; end

Loan = Struct.new(:member, :book, :due)

def money(c) = format("%d.%02d", c / 100, c % 100)

def member!(s) = s.match?(/\A[a-z]{1,12}\z/) ? s : raise(BadLine, "bad member")
def book!(s) = s.match?(/\A[A-Z][A-Z0-9]{0,7}\z/) ? s : raise(BadLine, "bad book")

def amount!(s)
  m = s.match(/\A(\d+)(?:\.(\d\d?))?\z/) or raise BadLine, "bad amount"
  c = m[1].to_i * 100 + (m[2] || "").ljust(2, "0").to_i
  raise BadLine, "bad amount" if c.zero?
  c
end

def books!(s)
  bs = s.split(",", -1)
  raise BadLine, "bad book" if bs.empty? || bs.size > 3 || bs.uniq.size != bs.size
  bs.each { |b| book!(b) }
  bs
end
ARITY = { "CHECKOUT" => 4, "RETURN" => 3, "RESERVE" => 4, "PAY" => 4 }.freeze

loans = {}                              # book => Loan
holds = {}                              # book => member
queues = Hash.new { |h, k| h[k] = [] }  # book => [member]
owes = Hash.new(0)
members = {}
today = 0
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    raise BadLine, "bad day" unless f[0].match?(/\A\d+\z/) && f[0].to_i <= 100_000
    day = f[0].to_i
    raise BadLine, "day goes backwards" if day < today
    today = day
    arity = ARITY[f[1]] or raise BadLine, "unknown command"
    raise BadLine, "wrong field count" unless f.size == arity
    case f[1]
    when "CHECKOUT"
      m = member!(f[2])
      bs = books!(f[3])
      bs.each do |b|
        raise Refused, "#{b} is on loan" if loans[b]
        raise Refused, "#{b} is held for #{holds[b]}" if holds[b] && holds[b] != m
      end
      mine = loans.values.select { |l| l.member == m }
      raise Refused, "#{m} has overdue books" if mine.any? { |l| today > l.due }
      raise Refused, "#{m} has #{mine.size} loans" if mine.size + bs.size > 3
      raise Refused, "#{m} owes #{money(owes[m])}" if owes[m] >= 1000
      bs.each do |b|
        holds.delete(b)
        loans[b] = Loan.new(m, b, today + 14)
      end
      members[m] = true
      puts "#{m} borrowed #{bs.join(", ")}, due day #{today + 14}"
    when "RETURN"
      bs = books!(f[2])
      bs.each { |b| raise Refused, "#{b} is not on loan" unless loans[b] }
      bs.each do |b|
        loan = loans.delete(b)
        late = today - loan.due
        if late > 0
          fine = [late * 25, 500].min
          owes[loan.member] += fine
          puts "#{loan.member} returned #{b}, #{late} days late, fine #{money(fine)}"
        else
          puts "#{loan.member} returned #{b}"
        end
        if (nxt = queues[b].shift)
          holds[b] = nxt
          puts "#{b} held for #{nxt}"
        end
      end
    when "RESERVE"
      m = member!(f[2])
      b = book!(f[3])
      raise Refused, "#{m} already has #{b}" if loans[b]&.member == m
      raise Refused, "#{m} already reserved #{b}" if holds[b] == m || queues[b].include?(m)
      raise Refused, "#{b} is available" unless loans[b] || holds[b]
      queues[b] << m
      members[m] = true
      puts "reserved #{b} for #{m} (position #{queues[b].size})"
    when "PAY"
      m = member!(f[2])
      amt = amount!(f[3])
      raise Refused, "#{m} owes only #{money(owes[m])}" if amt > owes[m]
      owes[m] -= amt
      puts "#{m} paid #{money(amt)}, owes #{money(owes[m])}"
    end
  rescue BadLine => e
    puts "line #{lineno}: error: #{e.message}"
  rescue Refused => e
    puts "line #{lineno}: refused: #{e.message}"
  end
end

puts format("%-12s %5s %8s", "member", "loans", "owes")
members.keys.sort.each do |m|
  puts format("%-12s %5d %8s", m, loans.values.count { |l| l.member == m }, money(owes[m]))
end
puts "overdue on day #{today}:"
late = loans.values.select { |l| today > l.due }.sort_by { |l| [l.due, l.book] }
puts "  none" if late.empty?
late.each { |l| puts "  #{l.book} #{l.member} due #{l.due} (#{today - l.due} days)" }
