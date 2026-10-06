COINS = [5, 10, 25, 50, 100, 200]
def money(c) = format("%d.%02d", c / 100, c % 100)
def mval(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil

slots = {}
tubes = Hash.new(0)
credit = 0
inserted = []
sold = Hash.new { |h, k| h[k] = [0, 0] }
n = 0
$stdin.each_line do |raw|
  n += 1
  line = raw.strip
  next if line.empty?
  f = line.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  need = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }[f[0]]
  if need.nil?
    err.("unknown command")
    next
  end
  if f.size != need
    err.("wrong field count")
    next
  end
  case f[0]
  when "SLOT"
    code, name, price, count = f[1], f[2], f[3], f[4]
    if code !~ /\A[A-Z]\d\z/ then err.("bad slot")
    elsif name !~ /\A[a-z]{1,12}\z/ then err.("bad name")
    elsif mval(price).nil? then err.("bad money")
    elsif count !~ /\A\d+\z/ || count.to_i > 99 then err.("bad count")
    else
      slots[code] = [name, mval(price), count.to_i]
    end
  when "TUBE"
    v = mval(f[1])
    if v.nil? then err.("bad money")
    elsif !COINS.include?(v) then err.("bad coin")
    elsif f[2] !~ /\A\d+\z/ || f[2].to_i > 999 then err.("bad count")
    else
      tubes[v] += f[2].to_i
    end
  when "COIN"
    v = mval(f[1])
    if v.nil? then err.("bad money")
    elsif !COINS.include?(v) then puts "rejected #{f[1]}"
    elsif credit + v > 500 then puts "rejected #{f[1]} (credit limit)"
    else
      tubes[v] += 1
      credit += v
      inserted << v
      puts "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if s.nil?
      puts "no slot #{f[1]}"
    elsif s[2] == 0
      puts "sold out #{f[1]}"
    elsif credit < s[1]
      puts "insert #{money(s[1] - credit)} more"
    else
      change = credit - s[1]
      rem = change
      paid = []
      take = Hash.new(0)
      COINS.reverse_each do |c|
        k = [rem / c, tubes[c]].min
        take[c] = k
        rem -= k * c
        k.times { paid << c }
      end
      if rem != 0
        puts "exact change needed"
      else
        take.each { |c, k| tubes[c] -= k }
        s[2] -= 1
        sold[s[0]][0] += 1
        sold[s[0]][1] += s[1]
        credit = 0
        inserted = []
        out = "vend #{s[0]}, change #{money(change)}"
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
if sold.empty?
  puts "  none"
else
  sold.sort_by { |name, (_, rev)| [-rev, name] }.each do |name, (cnt, rev)|
    puts format("  %-12s %3d %8s", name, cnt, money(rev))
  end
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
