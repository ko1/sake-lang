def money(c) = format("%d.%02d", c / 100, c % 100)
def parse_money(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil

COINS = [5, 10, 25, 50, 100, 200]
slots = {}
tubes = Hash.new(0)
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }
nf = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  cmd = f[0]
  unless nf[cmd]
    puts "line #{n}: error: unknown command"; next
  end
  if f.size != nf[cmd]
    puts "line #{n}: error: wrong field count"; next
  end
  err = nil
  case cmd
  when "SLOT"
    err = "bad slot" unless f[1] =~ /\A[A-Z][0-9]\z/
    err ||= "bad name" unless f[2] =~ /\A[a-z]{1,12}\z/
    err ||= "bad money" unless (price = parse_money(f[3]))
    err ||= "bad count" unless f[4] =~ /\A\d+\z/ && f[4].to_i <= 99
  when "TUBE"
    v = parse_money(f[1])
    err = "bad coin" unless v && COINS.include?(v)
    err ||= "bad count" unless f[2] =~ /\A\d+\z/ && f[2].to_i <= 999
  when "COIN"
    err = "bad money" unless (v = parse_money(f[1]))
  end
  if err
    puts "line #{n}: error: #{err}"; next
  end

  credit = inserted.sum
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
      puts "credit #{money(credit + v)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if !s
      puts "no slot #{f[1]}"
    elsif s[:count] == 0
      puts "sold out #{f[1]}"
    elsif credit < s[:price]
      puts "insert #{money(s[:price] - credit)} more"
    else
      change = credit - s[:price]
      rest = change
      paid = []
      avail = tubes.dup
      COINS.reverse_each do |c|
        while rest >= c && avail[c] > 0
          avail[c] -= 1
          rest -= c
          paid << c
        end
      end
      if rest != 0
        puts "exact change needed"
      else
        paid.each { |c| tubes[c] -= 1 }
        s[:count] -= 1
        sales[s[:name]][0] += 1
        sales[s[:name]][1] += s[:price]
        inserted = []
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
      inserted = []
    end
  end
end

credit = inserted.sum
puts "credit #{money(credit)} kept" if credit != 0
puts "sales:"
if sales.empty?
  puts "  none"
else
  sales.sort_by { |name, (_, rev)| [-rev, name] }.each do |name, (cnt, rev)|
    puts format("  %-12s %3d %8s", name, cnt, money(rev))
  end
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
