def money(c)
  format("%d.%02d", c / 100, c % 100)
end

COINS = [5, 10, 25, 50, 100, 200]
FIELDS = {"SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1}
MONEY = /\A\d+\.\d\d\z/

def cents(s)
  s.delete(".").to_i
end

slots = {}
tubes = Hash.new(0)
credit = 0
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  e = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless FIELDS.key?(cmd)
    e.call("unknown command"); next
  end
  if f.size != FIELDS[cmd]
    e.call("wrong field count"); next
  end
  case cmd
  when "SLOT"
    _, code, name, price, count = f
    if code !~ /\A[A-Z][0-9]\z/ then e.call("bad slot"); next end
    if name !~ /\A[a-z]{1,12}\z/ then e.call("bad name"); next end
    if price !~ MONEY then e.call("bad money"); next end
    if count !~ /\A\d+\z/ || count.to_i > 99 then e.call("bad count"); next end
    slots[code] = {name: name, price: cents(price), count: count.to_i}
  when "TUBE"
    _, coin, count = f
    if coin !~ MONEY then e.call("bad money"); next end
    if !COINS.include?(cents(coin)) then e.call("bad coin"); next end
    if count !~ /\A\d+\z/ || count.to_i > 999 then e.call("bad count"); next end
    tubes[cents(coin)] += count.to_i
  when "COIN"
    if f[1] !~ MONEY then e.call("bad money"); next end
    v = cents(f[1])
    if !COINS.include?(v)
      puts "rejected #{money(v)}"
    elsif credit + v > 500
      puts "rejected #{money(v)} (credit limit)"
    else
      tubes[v] += 1
      credit += v
      inserted << v
      puts "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if s.nil? then puts "no slot #{f[1]}"
    elsif s[:count] <= 0 then puts "sold out #{f[1]}"
    elsif credit < s[:price] then puts "insert #{money(s[:price] - credit)} more"
    else
      need = credit - s[:price]
      paid = []
      COINS.reverse_each do |c|
        k = [need / c, tubes[c]].min
        k.times { paid << c }
        need -= k * c
      end
      if need != 0
        puts "exact change needed"
      else
        paid.each { |c| tubes[c] -= 1 }
        s[:count] -= 1
        sales[s[:name]][0] += 1
        sales[s[:name]][1] += s[:price]
        change = credit - s[:price]
        credit = 0
        inserted = []
        out = "vend #{s[:name]}, change #{money(change)}"
        out += " [#{paid.map { |c| money(c) }.join(" ")}]" if change != 0
        puts out
      end
    end
  when "CANCEL"
    if credit == 0
      puts "nothing to return"
    else
      inserted.each { |c| tubes[c] -= 1 }
      puts "returned #{money(credit)} [#{inserted.map { |c| money(c) }.join(" ")}]"
      credit = 0
      inserted = []
    end
  end
end

puts "credit #{money(credit)} kept" if credit != 0
puts "sales:"
if sales.empty?
  puts "  none"
else
  sales.sort_by { |k, v| [-v[1], k.b] }.each do |k, v|
    puts format("  %-12s %3d %8s", k, v[0], money(v[1]))
  end
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
