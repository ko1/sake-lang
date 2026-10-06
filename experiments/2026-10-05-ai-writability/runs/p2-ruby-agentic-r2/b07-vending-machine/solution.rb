COINS = [5, 10, 25, 50, 100, 200].freeze
def money(c) = format("%d.%02d", c / 100, c % 100)
def parse_money(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil

slots = {}
tube = Hash.new(0)
credit = 0
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }
ARGS = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

$stdin.each_line.with_index(1) do |raw, n|
  next if raw.strip.empty?
  f = raw.strip.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless ARGS.key?(cmd)
    err.("unknown command"); next
  end
  if f.size != ARGS[cmd]
    err.("wrong field count"); next
  end
  case cmd
  when "SLOT"
    unless f[1] =~ /\A[A-Z]\d\z/ then err.("bad slot"); next end
    unless f[2] =~ /\A[a-z]{1,12}\z/ then err.("bad name"); next end
    price = parse_money(f[3])
    unless price then err.("bad money"); next end
    unless f[4] =~ /\A\d+\z/ && f[4].to_i <= 99 then err.("bad count"); next end
    slots[f[1]] = { name: f[2], price: price, count: f[4].to_i }
  when "TUBE"
    v = parse_money(f[1])
    unless v && COINS.include?(v) then err.("bad coin"); next end
    unless f[2] =~ /\A\d+\z/ && f[2].to_i <= 999 then err.("bad count"); next end
    tube[v] += f[2].to_i
  when "COIN"
    v = parse_money(f[1])
    unless v then err.("bad money"); next end
    if !COINS.include?(v)
      puts "rejected #{money(v)}"
    elsif credit + v > 500
      puts "rejected #{money(v)} (credit limit)"
    else
      tube[v] += 1
      credit += v
      inserted << v
      puts "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if !s then puts "no slot #{f[1]}"
    elsif s[:count] == 0 then puts "sold out #{f[1]}"
    elsif credit < s[:price] then puts "insert #{money(s[:price] - credit)} more"
    else
      need = credit - s[:price]
      paid = []
      COINS.reverse_each do |c|
        k = [need / c, tube[c]].min
        k.times { paid << c }
        need -= k * c
      end
      if need != 0
        puts "exact change needed"
      else
        paid.each { |c| tube[c] -= 1 }
        s[:count] -= 1
        sales[s[:name]][0] += 1
        sales[s[:name]][1] += s[:price]
        chg = credit - s[:price]
        credit = 0
        inserted = []
        out = "vend #{s[:name]}, change #{money(chg)}"
        out += " [#{paid.map { |c| money(c) }.join(' ')}]" if chg != 0
        puts out
      end
    end
  when "CANCEL"
    if credit == 0
      puts "nothing to return"
    else
      inserted.each { |c| tube[c] -= 1 }
      puts "returned #{money(credit)} [#{inserted.map { |c| money(c) }.join(' ')}]"
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
  sales.sort_by { |name, (_, rev)| [-rev, name] }.each do |name, (cnt, rev)|
    puts format("  %-12s %3d %8s", name, cnt, money(rev))
  end
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tube[c]}" }.join(" ")
