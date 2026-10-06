def money(c)
  s = format("%d.%02d", c.abs / 100, c.abs % 100)
  c < 0 ? "-" + s : s
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
end

Acct = Struct.new(:balance, :limit, :lowest, :txns, :outs)

def set_bal(a, v)
  a.balance = v
  a.lowest = v if v < a.lowest
end

accts = {}
month = 0
FIELDS = {"OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1}

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  unless FIELDS.key?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != FIELDS[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |n|
      a = accts[n]
      if a.balance < 0
        over = -a.balance
        ch = (over * 15 + 999) / 1000
        if ch > 0
          set_bal(a, a.balance - ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a.balance > 0
        ad = a.balance * 25 / 10000
        if ad > 0
          set_bal(a, a.balance + ad)
          puts "#{n} interest +#{money(ad)}"
        end
      end
      if a.outs > 4
        set_bal(a, a.balance - 200)
        puts "#{n} fee -2.00"
      end
      a.outs = 0
    end
    next
  end
  names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
  if (bad = names.find { |n| n !~ /\A[a-z]{1,16}\z/ })
    puts "line #{no}: error: bad name"
    next
  end
  amt = cents(f[-1])
  if amt.nil? || (cmd != "OPEN" && amt == 0)
    puts "line #{no}: error: bad amount"
    next
  end
  if cmd == "OPEN"
    if accts.key?(names[0])
      puts "line #{no}: error: account #{names[0]} exists"
    else
      accts[names[0]] = Acct.new(0, amt, 0, 0, 0)
    end
    next
  end
  if (miss = names.find { |n| !accts.key?(n) })
    puts "line #{no}: error: no account #{miss}"
    next
  end
  case cmd
  when "DEPOSIT"
    a = accts[names[0]]
    set_bal(a, a.balance + amt)
    a.txns += 1
  when "WITHDRAW"
    a = accts[names[0]]
    if a.balance - amt < -a.limit
      puts "line #{no}: error: insufficient funds in #{names[0]}"
    else
      set_bal(a, a.balance - amt)
      a.txns += 1
      a.outs += 1
    end
  when "TRANSFER"
    if names[0] == names[1]
      puts "line #{no}: error: same account"
      next
    end
    a = accts[names[0]]
    b = accts[names[1]]
    if a.balance - amt < -a.limit
      puts "line #{no}: error: insufficient funds in #{names[0]}"
    else
      set_bal(a, a.balance - amt)
      set_bal(b, b.balance + amt)
      a.txns += 1
      b.txns += 1
      a.outs += 1
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
