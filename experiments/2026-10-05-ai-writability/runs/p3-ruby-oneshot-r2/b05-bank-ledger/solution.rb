def money(c)
  (c < 0 ? "-" : "") + format("%d.%02d", c.abs / 100, c.abs % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

Acct = Struct.new(:bal, :limit, :low, :txns, :wd)
accts = {}
month = 0

touch = lambda do |a|
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  cmd = f[0]
  want = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }[cmd]
  if want.nil?
    puts "line #{n}: error: unknown command"
    next
  end
  if f.size != want
    puts "line #{n}: error: wrong field count"
    next
  end
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |name|
      a = accts[name]
      if a.bal < 0
        ch = ((-a.bal) * 15 + 999) / 1000
        if ch > 0
          a.bal -= ch
          touch.call(a)
          puts "#{name} interest -#{money(ch)}"
        end
      elsif a.bal > 0
        gain = a.bal * 25 / 10000
        if gain > 0
          a.bal += gain
          touch.call(a)
          puts "#{name} interest +#{money(gain)}"
        end
      end
      if a.wd > 4
        a.bal -= 200
        touch.call(a)
        puts "#{name} fee -2.00"
      end
      a.wd = 0
    end
    next
  end
  nnames = cmd == "TRANSFER" ? 2 : 1
  names = f[1, nnames]
  bad = names.find { |s| s !~ /\A[a-z]{1,16}\z/ }
  if bad
    puts "line #{n}: error: bad name"
    next
  end
  amt = cents(f[1 + nnames])
  if amt.nil? || (cmd != "OPEN" && amt <= 0)
    puts "line #{n}: error: bad amount"
    next
  end
  if cmd == "OPEN"
    if accts.key?(names[0])
      puts "line #{n}: error: account #{names[0]} exists"
    else
      accts[names[0]] = Acct.new(0, amt, 0, 0, 0)
    end
    next
  end
  miss = names.find { |s| !accts.key?(s) }
  if miss
    puts "line #{n}: error: no account #{miss}"
    next
  end
  case cmd
  when "DEPOSIT"
    a = accts[names[0]]
    a.bal += amt
    a.txns += 1
    touch.call(a)
  when "WITHDRAW"
    a = accts[names[0]]
    if a.bal - amt < -a.limit
      puts "line #{n}: error: insufficient funds in #{names[0]}"
      next
    end
    a.bal -= amt
    a.txns += 1
    a.wd += 1
    touch.call(a)
  when "TRANSFER"
    if names[0] == names[1]
      puts "line #{n}: error: same account"
      next
    end
    a = accts[names[0]]
    b = accts[names[1]]
    if a.bal - amt < -a.limit
      puts "line #{n}: error: insufficient funds in #{names[0]}"
      next
    end
    a.bal -= amt
    a.txns += 1
    a.wd += 1
    touch.call(a)
    b.bal += amt
    b.txns += 1
    touch.call(b)
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |name, a| [-a.bal, name.b] }.each do |name, a|
    puts format("%-16s %12s %12s %5d", name, money(a.bal), money(a.low), a.txns)
  end
  puts "total: #{money(accts.values.sum(&:bal))}"
end
