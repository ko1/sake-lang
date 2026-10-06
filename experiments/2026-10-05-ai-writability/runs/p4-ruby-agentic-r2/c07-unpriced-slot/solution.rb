COINS = [200, 100, 50, 25, 10, 5].freeze
CREDIT_LIMIT = 500

class BadLine < StandardError; end

Slot = Struct.new(:name, :price, :count)

def money(c) = format("%d.%02d", c / 100, c % 100)

def money!(s)
  m = s.match(/\A(\d+)\.(\d\d)\z/) or raise BadLine, "bad money"
  m[1].to_i * 100 + m[2].to_i
end

def count!(s, max)
  raise BadLine, "bad count" unless s.match?(/\A\d+\z/) && s.to_i <= max
  s.to_i
end

# Greedy change from the tubes, largest coin first; nil if it cannot be made exactly.
def make_change(tubes, amount)
  out = []
  COINS.each do |c|
    n = [tubes[c], amount / c].min
    out.concat([c] * n)
    amount -= c * n
  end
  amount.zero? ? out : nil
end

ARITY = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }.freeze

slots = {}
tubes = COINS.to_h { |c| [c, 0] }
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    arity = ARITY[f[0]] or raise BadLine, "unknown command"
    raise BadLine, "wrong field count" unless f.size == arity
    case f[0]
    when "SLOT"
      code = f[1].match?(/\A[A-Z][0-9]\z/) ? f[1] : raise(BadLine, "bad slot")
      raise BadLine, "bad name" unless f[2].match?(/\A[a-z]{1,12}\z/)
      slots[code] = Slot.new(f[2], (f[3] == "-" ? nil : money!(f[3])), count!(f[4], 99))
    when "TUBE"
      c = money!(f[1])
      raise BadLine, "bad coin" unless COINS.include?(c)
      tubes[c] += count!(f[2], 999)
    when "COIN"
      c = money!(f[1])
      credit = inserted.sum
      if !COINS.include?(c)
        puts "rejected #{money(c)}"
      elsif credit + c > CREDIT_LIMIT
        puts "rejected #{money(c)} (credit limit)"
      else
        inserted << c
        tubes[c] += 1
        puts "credit #{money(credit + c)}"
      end
    when "SELECT"
      code = f[1]
      slot = slots[code]
      credit = inserted.sum
      if slot.nil?
        puts "no slot #{code}"
      elsif slot.count.zero?
        puts "sold out #{code}"
      elsif slot.price.nil?
        puts "no price #{code}"
      elsif credit < slot.price
        puts "insert #{money(slot.price - credit)} more"
      elsif (change = make_change(tubes, credit - slot.price)).nil?
        puts "exact change needed"
      else
        change.each { |c| tubes[c] -= 1 }
        slot.count -= 1
        inserted.clear
        sales[slot.name][0] += 1
        sales[slot.name][1] += slot.price
        coins = change.empty? ? "" : " [#{change.map { money(_1) }.join(" ")}]"
        puts "vend #{slot.name}, change #{money(credit - slot.price)}#{coins}"
      end
    when "CANCEL"
      if inserted.empty?
        puts "nothing to return"
      else
        inserted.each { |c| tubes[c] -= 1 }
        puts "returned #{money(inserted.sum)} [#{inserted.map { money(_1) }.join(" ")}]"
        inserted.clear
      end
    end
  rescue BadLine => e
    puts "line #{lineno}: error: #{e.message}"
  end
end

puts "credit #{money(inserted.sum)} kept" unless inserted.empty?
puts "sales:"
puts "  none" if sales.empty?
sales.sort_by { |name, (n, rev)| [-rev, name] }.each do |name, (n, rev)|
  puts format("  %-12s %3d %8s", name, n, money(rev))
end
unpriced = slots.select { |_, sl| sl.price.nil? }.keys.sort
puts "unpriced: #{unpriced.join(" ")}" unless unpriced.empty?
puts "tubes: #{COINS.reverse.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")}"
