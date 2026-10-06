COINS = [5, 10, 25, 50, 100, 200]

def money(c) = format("%d.%02d", c / 100, c % 100)

def parse_money(s)
  return nil unless s.match?(/\A\d+\.\d\d\z/)
  s.delete(".").to_i
end

def lst(a) = "[" + a.map { |c| money(c) }.join(" ") + "]"

slots = {}
tubes = Hash.new(0)
credit = 0
inserted = []
sold = Hash.new(0)
rev = Hash.new(0)
ARGC = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  cmd = f[0]
  err = nil
  unless ARGC.key?(cmd)
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != ARGC[cmd]
    puts "line #{n}: error: wrong field count"
    next
  end
  case cmd
  when "SLOT"
    err = "bad slot" unless f[1].match?(/\A[A-Z]\d\z/)
    err ||= "bad name" unless f[2].match?(/\A[a-z]{1,12}\z/)
    price = parse_money(f[3])
    err ||= "bad money" unless price
    err ||= "bad count" unless f[4].match?(/\A\d+\z/) && f[4].to_i <= 99
  when "TUBE"
    v = parse_money(f[1])
    err = "bad coin" unless v && COINS.include?(v)
    err ||= "bad count" unless f[2].match?(/\A\d+\z/) && f[2].to_i <= 999
  when "COIN"
    v = parse_money(f[1])
    err = "bad money" unless v
  end
  if err
    puts "line #{n}: error: #{err}"
    next
  end

  case cmd
  when "SLOT"
    slots[f[1]] = { name: f[2], price: price, count: f[4].to_i }
  when "TUBE"
    tubes[v] += f[2].to_i
  when "COIN"
    if !COINS.include?(v)
      puts "rejected #{money(v)}"
    elsif credit + v > 500
      puts "rejected #{money(v)} (credit limit)"
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
      COINS.reverse_each do |c|
        k = [rem / c, tubes[c]].min
        k.times { paid << c }
        rem -= k * c
      end
      if rem != 0
        puts "exact change needed"
      else
        paid.each { |c| tubes[c] -= 1 }
        s[:count] -= 1
        sold[s[:name]] += 1
        rev[s[:name]] += s[:price]
        credit = 0
        inserted = []
        out = "vend #{s[:name]}, change #{money(change)}"
        out += " #{lst(paid)}" if change != 0
        puts out
      end
    end
  when "CANCEL"
    if credit == 0
      puts "nothing to return"
    else
      inserted.each { |c| tubes[c] -= 1 }
      puts "returned #{money(credit)} #{lst(inserted)}"
      credit = 0
      inserted = []
    end
  end
end

puts "credit #{money(credit)} kept" if credit != 0
puts "sales:"
names = sold.keys.sort_by { |nm| [-rev[nm], nm] }
if names.empty?
  puts "  none"
else
  names.each { |nm| puts format("  %-12s %3d %8s", nm, sold[nm], money(rev[nm])) }
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
