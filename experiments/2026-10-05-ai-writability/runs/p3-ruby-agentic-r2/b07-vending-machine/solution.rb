def money(c) = format("%d.%02d", c / 100, c % 100)
COINS = [5, 10, 25, 50, 100, 200]
MON = /\A(\d+)\.(\d\d)\z/
def cents(s) = (s =~ MON) ? $1.to_i * 100 + $2.to_i : nil
tubes = Hash.new(0)
slots = {}
sold = Hash.new(0); rev = Hash.new(0)
credit = 0
ins = []
ARGC = { "SLOT" => 6, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  e = ->(m) { puts "line #{n}: error: #{m}" }
  unless ARGC.key?(f[0]) then e.("unknown command"); next end
  if f.size != ARGC[f[0]] - (f[0] == "SLOT" ? 1 : 0) then e.("wrong field count"); next end
  case f[0]
  when "SLOT"
    (e.("bad slot"); next) unless f[1] =~ /\A[A-Z]\d\z/
    (e.("bad name"); next) unless f[2] =~ /\A[a-z]{1,12}\z/
    p = cents(f[3]); (e.("bad money"); next) unless p
    (e.("bad count"); next) unless f[4] =~ /\A\d{1,2}\z/
    slots[f[1]] = [f[2], p, f[4].to_i]
  when "TUBE"
    c = cents(f[1])
    (e.("bad coin"); next) unless c && COINS.include?(c)
    (e.("bad count"); next) unless f[2] =~ /\A\d{1,3}\z/
    tubes[c] += f[2].to_i
  when "COIN"
    c = cents(f[1]); (e.("bad money"); next) unless c
    if !COINS.include?(c) then puts "rejected #{money(c)}"
    elsif credit + c > 500 then puts "rejected #{money(c)} (credit limit)"
    else
      tubes[c] += 1; credit += c; ins << c
      puts "credit #{money(credit)}"
    end
  when "SELECT"
    s = slots[f[1]]
    if !s then puts "no slot #{f[1]}"
    elsif s[2] == 0 then puts "sold out #{f[1]}"
    elsif credit < s[1] then puts "insert #{money(s[1] - credit)} more"
    else
      ch = credit - s[1]; rem = ch; paid = []; use = Hash.new(0)
      COINS.reverse_each do |c|
        k = [rem / c, tubes[c]].min
        use[c] = k; rem -= k * c; k.times { paid << c }
      end
      if rem != 0 then puts "exact change needed"
      else
        use.each { |c, k| tubes[c] -= k }
        s[2] -= 1; sold[s[0]] += 1; rev[s[0]] += s[1]; credit = 0; ins = []
        puts "vend #{s[0]}, change #{money(ch)}" + (ch > 0 ? " [#{paid.map { |c| money(c) }.join(' ')}]" : "")
      end
    end
  when "CANCEL"
    if credit == 0 then puts "nothing to return"
    else
      ins.each { |c| tubes[c] -= 1 }
      puts "returned #{money(credit)} [#{ins.map { |c| money(c) }.join(' ')}]"
      credit = 0; ins = []
    end
  end
end
puts "credit #{money(credit)} kept" if credit != 0
puts "sales:"
names = sold.keys.sort_by { |k| [-rev[k], k] }
if names.empty? then puts "  none"
else names.each { |k| puts format("  %-12s %3d %8s", k, sold[k], money(rev[k])) } end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
