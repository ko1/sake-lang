def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(str)
  return nil unless str.match?(/\A\d+(\.\d{1,2})?\z/)
  i, fr = str.split(".", 2)
  i.to_i * 100 + (fr || "").ljust(2, "0").to_i
end

class Acct
  attr_accessor :balance, :limit, :lowest, :txns, :outs
  def initialize(limit)
    @balance = 0
    @limit = limit
    @lowest = 0
    @txns = 0
    @outs = 0
  end

  def change(d)
    @balance += d
    @lowest = @balance if @balance < @lowest
  end
end

accts = {}
month = 0
NAME_RE = /\A[a-z]{1,16}\z/

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.match?(/\A *\z/)
  f = line.split(/ +/).reject(&:empty?)
  cmd = f[0]
  want = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }[cmd]
  if want.nil?
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != want
    puts "line #{no}: error: wrong field count"
    next
  end

  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |n|
      a = accts[n]
      if a.balance < 0
        ch = (-a.balance * 15 + 999) / 1000
        if ch > 0
          a.change(-ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a.balance > 0
        ad = a.balance * 25 / 10000
        if ad > 0
          a.change(ad)
          puts "#{n} interest +#{money(ad)}"
        end
      end
      if a.outs > 4
        a.change(-200)
        puts "#{n} fee -2.00"
      end
      a.outs = 0
    end
    next
  end

  names = cmd == "TRANSFER" ? [f[1], f[2]] : [f[1]]
  amt_s = f[-1]
  if names.any? { |n| !n.match?(NAME_RE) }
    puts "line #{no}: error: bad name"
    next
  end
  amt = cents(amt_s)
  if amt.nil? || (amt == 0 && cmd != "OPEN")
    puts "line #{no}: error: bad amount"
    next
  end

  case cmd
  when "OPEN"
    if accts.key?(names[0])
      puts "line #{no}: error: account #{names[0]} exists"
    else
      accts[names[0]] = Acct.new(amt)
    end
  when "DEPOSIT"
    a = accts[names[0]]
    if a.nil?
      puts "line #{no}: error: no account #{names[0]}"
    else
      a.change(amt)
      a.txns += 1
    end
  when "WITHDRAW"
    a = accts[names[0]]
    if a.nil?
      puts "line #{no}: error: no account #{names[0]}"
    elsif a.balance - amt < -a.limit
      puts "line #{no}: error: insufficient funds in #{names[0]}"
    else
      a.change(-amt)
      a.txns += 1
      a.outs += 1
    end
  when "TRANSFER"
    a = accts[names[0]]
    b = accts[names[1]]
    if a.nil?
      puts "line #{no}: error: no account #{names[0]}"
    elsif b.nil?
      puts "line #{no}: error: no account #{names[1]}"
    elsif names[0] == names[1]
      puts "line #{no}: error: same account"
    elsif a.balance - amt < -a.limit
      puts "line #{no}: error: insufficient funds in #{names[0]}"
    else
      a.change(-amt)
      a.txns += 1
      a.outs += 1
      b.change(amt)
      b.txns += 1
    end
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |n, a| [-a.balance, n.b] }.each do |n, a|
    puts format("%-16s %12s %12s %5d", n, money(a.balance), money(a.lowest), a.txns)
  end
  puts "total: #{money(accts.values.sum(&:balance))}"
end
