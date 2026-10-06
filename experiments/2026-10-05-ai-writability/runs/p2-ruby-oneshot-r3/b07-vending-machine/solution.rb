COINS = [5, 10, 25, 50, 100, 200]
def money(c) = format("%d.%02d", c / 100, c % 100)
def parse_money(s)
  return nil unless s =~ /\A(\d+)\.(\d\d)\z/
  $1.to_i * 100 + $2.to_i
end

slots = {}  # code => [name, price, count]
tubes = Hash.new(0)
credit = 0
inserted = []
sales = Hash.new { |h, k| h[k] = [0, 0] }
out = []
counts = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty?
  f = line.split
  cmd = f[0]
  unless counts.key?(cmd)
    out << "line #{n}: error: unknown command"
    next
  end
  if f.size != counts[cmd]
    out << "line #{n}: error: wrong field count"
    next
  end
  case cmd
  when "SLOT"
    price = parse_money(f[3])
    if f[1] !~ /\A[A-Z]\d\z/
      out << "line #{n}: error: bad slot"
    elsif f[2] !~ /\A[a-z]{1,12}\z/
      out << "line #{n}: error: bad name"
    elsif price.nil?
      out << "line #{n}: error: bad money"
    elsif f[4] !~ /\A\d+\z/ || f[4].to_i > 99
      out << "line #{n}: error: bad count"
    else
      slots[f[1]] = [f[2], price, f[4].to_i]
    end
  when "TUBE"
    v = parse_money(f[1])
    if v.nil? || !COINS.include?(v)
      out << "line #{n}: error: bad coin"
    elsif f[2] !~ /\A\d+\z/ || f[2].to_i > 999
      out << "line #{n}: error: bad count"
    else
      tubes[v] += f[2].to_i
    end
  when "COIN"
    v = parse_money(f[1])
    if v.nil?
      out << "line #{n}: error: bad money"
    elsif !COINS.include?(v)
      out << "rejected #{money(v)}"
    elsif credit + v > 500
      out << "rejected #{money(v)} (credit limit)"
    else
      tubes[v] += 1
      inserted << v
      credit += v
      out << "credit #{money(credit)}"
    end
  when "SELECT"
    code = f[1]
    s = slots[code]
    if s.nil?
      out << "no slot #{code}"
    elsif s[2] == 0
      out << "sold out #{code}"
    elsif credit < s[1]
      out << "insert #{money(s[1] - credit)} more"
    else
      change = credit - s[1]
      rem = change
      paid = []
      COINS.reverse_each do |c|
        k = [rem / c, tubes[c]].min
        k.times { paid << c }
        rem -= k * c
      end
      if rem != 0
        out << "exact change needed"
      else
        paid.each { |c| tubes[c] -= 1 }
        s[2] -= 1
        sales[s[0]][0] += 1
        sales[s[0]][1] += s[1]
        credit = 0
        inserted = []
        msg = "vend #{s[0]}, change #{money(change)}"
        msg += " [#{paid.map { |c| money(c) }.join(' ')}]" if change != 0
        out << msg
      end
    end
  when "CANCEL"
    if credit == 0
      out << "nothing to return"
    else
      inserted.each { |c| tubes[c] -= 1 }
      out << "returned #{money(credit)} [#{inserted.map { |c| money(c) }.join(' ')}]"
      credit = 0
      inserted = []
    end
  end
end

out << "credit #{money(credit)} kept" if credit != 0
out << "sales:"
rows = sales.select { |_, (items, _)| items > 0 }.sort_by { |name, (_, rev)| [-rev, name] }
if rows.empty?
  out << "  none"
else
  rows.each { |name, (items, rev)| out << format("  %-12s %3d %8s", name, items, money(rev)) }
end
out << "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
puts out
