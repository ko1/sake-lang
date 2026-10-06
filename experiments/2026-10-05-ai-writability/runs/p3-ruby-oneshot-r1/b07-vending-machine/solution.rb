COINS = [5, 10, 25, 50, 100, 200]

def money(c)
  format("%d.%02d", c / 100, c % 100)
end

def parse_money(s)
  return nil unless s =~ /\A(\d+)\.(\d\d)\z/
  $1.to_i * 100 + $2.to_i
end

slots = {}
tubes = Hash.new(0)
credit = 0
inserted = []
sold = Hash.new(0)
rev = Hash.new(0)
out = []
need = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  cmd = f[0]
  unless need.key?(cmd)
    out << "line #{n}: error: unknown command"
    next
  end
  if f.size != need[cmd]
    out << "line #{n}: error: wrong field count"
    next
  end
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case cmd
  when "SLOT"
    code, name, ps, cs = f[1], f[2], f[3], f[4]
    if code !~ /\A[A-Z]\d\z/
      err.("bad slot")
    elsif name !~ /\A[a-z]{1,12}\z/
      err.("bad name")
    elsif (price = parse_money(ps)).nil?
      err.("bad money")
    elsif cs !~ /\A\d+\z/ || cs.to_i > 99
      err.("bad count")
    else
      slots[code] = { name: name, price: price, count: cs.to_i }
    end
  when "TUBE"
    c = parse_money(f[1])
    if c.nil? || !COINS.include?(c)
      err.("bad coin")
    elsif f[2] !~ /\A\d+\z/ || f[2].to_i > 999
      err.("bad count")
    else
      tubes[c] += f[2].to_i
    end
  when "COIN"
    v = parse_money(f[1])
    if v.nil?
      err.("bad money")
    elsif !COINS.include?(v)
      out << "rejected #{f[1]}"
    elsif credit + v > 500
      out << "rejected #{money(v)} (credit limit)"
    else
      tubes[v] += 1
      inserted << v
      credit += v
      out << "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if s.nil?
      out << "no slot #{f[1]}"
    elsif s[:count] <= 0
      out << "sold out #{f[1]}"
    elsif credit < s[:price]
      out << "insert #{money(s[:price] - credit)} more"
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
        out << "exact change needed"
      else
        take.each { |c, k| tubes[c] -= k }
        s[:count] -= 1
        sold[s[:name]] += 1
        rev[s[:name]] += s[:price]
        credit = 0
        inserted = []
        line = "vend #{s[:name]}, change #{money(change)}"
        line += " [#{paid.map { |c| money(c) }.join(' ')}]" if change != 0
        out << line
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
if sold.empty?
  out << "  none"
else
  sold.keys.sort_by { |nm| [-rev[nm], nm] }.each do |nm|
    out << format("  %-12s %3d %8s", nm, sold[nm], money(rev[nm]))
  end
end
out << "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
puts out
