def money(c) = format("%d.%02d", c / 100, c % 100)
def parse_money(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil

COINS = [5, 10, 25, 50, 100, 200]
tubes = Hash.new(0)
slots = {}
credit = 0
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }
out = []

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.strip.split(" ")
  next if f.empty?
  err = ->(m) { out << "line #{n}: error: #{m}" }
  need = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }[f[0]]
  (err.("unknown command"); next) unless need
  (err.("wrong field count"); next) unless f.size == need
  case f[0]
  when "SLOT"
    (err.("bad slot"); next) unless f[1] =~ /\A[A-Z]\d\z/
    (err.("bad name"); next) unless f[2] =~ /\A[a-z]{1,12}\z/
    price = parse_money(f[3])
    (err.("bad money"); next) unless price
    (err.("bad count"); next) unless f[4] =~ /\A\d+\z/ && f[4].to_i <= 99
    slots[f[1]] = [f[2], price, f[4].to_i]
  when "TUBE"
    v = parse_money(f[1])
    (err.("bad coin"); next) unless v && COINS.include?(v)
    (err.("bad count"); next) unless f[2] =~ /\A\d+\z/ && f[2].to_i <= 999
    tubes[v] += f[2].to_i
  when "COIN"
    v = parse_money(f[1])
    (err.("bad money"); next) unless v
    if !COINS.include?(v)
      out << "rejected #{money(v)}"
    elsif credit + v > 500
      out << "rejected #{money(v)} (credit limit)"
    else
      tubes[v] += 1
      credit += v
      inserted << v
      out << "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if !s then out << "no slot #{f[1]}"; next end
    if s[2] == 0 then out << "sold out #{f[1]}"; next end
    if credit < s[1] then out << "insert #{money(s[1] - credit)} more"; next end
    change = credit - s[1]
    rem = change
    paid = []
    COINS.reverse_each do |c|
      k = [rem / c, tubes[c]].min
      k.times { paid << c }
      rem -= k * c
    end
    if rem != 0 then out << "exact change needed"; next end
    paid.each { |c| tubes[c] -= 1 }
    s[2] -= 1
    credit = 0
    inserted = []
    sales[s[0]][0] += 1
    sales[s[0]][1] += s[1]
    l = "vend #{s[0]}, change #{money(change)}"
    l += " [#{paid.map { |c| money(c) }.join(' ')}]" if change != 0
    out << l
  when "CANCEL"
    if credit == 0 then out << "nothing to return"; next end
    inserted.each { |c| tubes[c] -= 1 }
    out << "returned #{money(credit)} [#{inserted.map { |c| money(c) }.join(' ')}]"
    credit = 0
    inserted = []
  end
end

out << "credit #{money(credit)} kept" if credit != 0
out << "sales:"
if sales.empty?
  out << "  none"
else
  sales.sort_by { |nm, (_, r)| [-r, nm] }.each { |nm, (c, r)| out << format("  %-12s %3d %8s", nm, c, money(r)) }
end
out << "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
puts out
