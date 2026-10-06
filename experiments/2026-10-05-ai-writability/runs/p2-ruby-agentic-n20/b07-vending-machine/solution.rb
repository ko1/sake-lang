def money(c) = format("%d.%02d", c / 100, c % 100)
def cents(s) = s.sub(".", "").to_i

COINS = [5, 10, 25, 50, 100, 200].freeze
MONEY = /\A\d+\.\d\d\z/
COUNTS = { "SLOT" => 5, "TUBE" => 3, "COIN" => 2, "SELECT" => 2, "CANCEL" => 1 }.freeze

slots = {}
tubes = Hash.new(0)
inserted = []
credit = 0
sold = Hash.new(0)
rev = Hash.new(0)

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  unless COUNTS.key?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != COUNTS[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  err = nil
  case cmd
  when "SLOT"
    err = "bad slot" if f[1] !~ /\A[A-Z]\d\z/
    err ||= "bad name" if f[2] !~ /\A[a-z]{1,12}\z/
    err ||= "bad money" if f[3] !~ MONEY
    err ||= "bad count" if f[4] !~ /\A\d+\z/ || f[4].to_i > 99
  when "TUBE"
    err = "bad coin" if f[1] !~ MONEY || !COINS.include?(cents(f[1]))
    err ||= "bad count" if f[2] !~ /\A\d+\z/ || f[2].to_i > 999
  when "COIN"
    err = "bad money" if f[1] !~ MONEY
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "SLOT"
    slots[f[1]] = [f[2], cents(f[3]), f[4].to_i]
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
    elsif s[2] == 0
      puts "sold out #{f[1]}"
    elsif credit < s[1]
      puts "insert #{money(s[1] - credit)} more"
    else
      change = credit - s[1]
      need = change
      paid = []
      COINS.reverse_each do |c|
        n = [need / c, tubes[c]].min
        n.times { paid << c }
        need -= n * c
      end
      if need != 0
        puts "exact change needed"
      else
        paid.each { |c| tubes[c] -= 1 }
        s[2] -= 1
        sold[s[0]] += 1
        rev[s[0]] += s[1]
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
names = sold.keys.sort_by { |n| [-rev[n], n.b] }
if names.empty?
  puts "  none"
else
  names.each { |n| puts format("  %-12s %3d %8s", n, sold[n], money(rev[n])) }
end
puts "tubes: " + COINS.map { |c| "#{money(c)}x#{tubes[c]}" }.join(" ")
