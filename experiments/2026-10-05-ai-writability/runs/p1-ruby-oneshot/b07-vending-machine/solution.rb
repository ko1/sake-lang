def money(c) = format("%d.%02d", c / 100, c % 100)

COINS = [5, 10, 25, 50, 100, 200]
MONEY_RE = /\A(\d+)\.(\d\d)\z/
FIELDS = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

def cents(s)
  m = MONEY_RE.match(s)
  m && m[1].to_i * 100 + m[2].to_i
end

slots = {}
tubes = Hash.new(0)
inserted = []
credit = 0
sales = Hash.new { |h, k| h[k] = [0, 0] }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  cmd = f[0]
  unless FIELDS.key?(cmd)
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != FIELDS[cmd]
    puts "line #{n}: error: wrong field count"
    next
  end
  err = nil
  case cmd
  when "SLOT"
    if !f[1].match?(/\A[A-Z][0-9]\z/) then err = "bad slot"
    elsif !f[2].match?(/\A[a-z]{1,12}\z/) then err = "bad name"
    elsif !cents(f[3]) then err = "bad money"
    elsif !(f[4].match?(/\A\d+\z/) && f[4].to_i <= 99) then err = "bad count"
    end
  when "TUBE"
    c = cents(f[1])
    if c.nil? || !COINS.include?(c) then err = "bad coin"
    elsif !(f[2].match?(/\A\d+\z/) && f[2].to_i <= 999) then err = "bad count"
    end
  when "COIN"
    err = "bad money" unless cents(f[1])
  end
  if err
    puts "line #{n}: error: #{err}"
    next
  end

  case cmd
  when "SLOT"
    slots[f[1]] = { name: f[2], price: cents(f[3]), count: f[4].to_i }
  when "TUBE"
    tubes[cents(f[1])] += f[2].to_i
  when "COIN"
    v = cents(f[1])
    if !COINS.include?(v)
      puts "rejected #{f[1]}"
    elsif credit + v > 500
      puts "rejected #{f[1]} (credit limit)"
    else
      tubes[v] += 1
      inserted << v
      credit += v
      puts "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if s.nil?
      puts "no slot #{f[1]}"
    elsif s[:count] == 0
      puts "sold out #{f[1]}"
    elsif credit < s[:price]
      puts "insert #{money(s[:price] - credit)} more"
    else
      change = credit - s[:price]
      rem = change
      paid = []
      take = Hash.new(0)
      COINS.reverse_each do |c|
        k = [rem / c, tubes[c]].min
        next if k <= 0
        take[c] = k
        rem -= k * c
        k.times { paid << c }
      end
      if rem != 0
        puts "exact change needed"
      else
        take.each { |c, k| tubes[c] -= k }
        s[:count] -= 1
        credit = 0
        inserted = []
        e = sales[s[:name]]
        e[0] += 1
        e[1] += s[:price]
        out = "vend #{s[:name]}, change #{money(change)}"
        out += " [#{paid.map { |c| money(c) }.join(' ')}]" if change != 0
        puts out
      end
    end
  when "CANCEL"
    if credit == 0
      puts "nothing to return"
    else
      inserted.each { |c| tubes[c] -= 1 }
      puts "returned #{money(credit)} [#{inserted.map { |c| money(c) }.join(' ')}]"
      credit = 0
      inserted = []
    end
  end
end

puts "credit #{money(credit)} kept" if credit != 0
puts "sales:"
rows = sales.select { |_, (i, _)| i > 0 }.sort_by { |name, (_, rev)| [-rev, name] }
if rows.empty?
  puts "  none"
else
  rows.each { |name, (i, rev)| puts format("  %-12s %3d %8s", name, i, money(rev)) }
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
