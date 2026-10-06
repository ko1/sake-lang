def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  i, f = s.split(".")
  i.to_i * 100 + (f ? (f + "0")[0, 2].to_i : 0)
end

Acct = Struct.new(:bal, :limit, :low, :txns, :outs)
accts = {}
month = 0
FC = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }

change = lambda do |a, d|
  a.bal += d
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |line, n|
  f = line.chomp.split(" ")
  next if f.empty?
  err = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless FC.key?(cmd)
    err.call("unknown command"); next
  end
  if f.size != FC[cmd]
    err.call("wrong field count"); next
  end
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |name|
      a = accts[name]
      if a.bal < 0
        ch = (-a.bal * 15 + 999) / 1000
        if ch > 0
          change.call(a, -ch)
          puts "#{name} interest #{money(-ch)}"
        end
      elsif a.bal > 0
        ch = a.bal * 25 / 10000
        if ch > 0
          change.call(a, ch)
          puts "#{name} interest +#{money(ch)}"
        end
      end
      if a.outs > 4
        change.call(a, -200)
        puts "#{name} fee -2.00"
      end
      a.outs = 0
    end
    next
  end
  names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
  amt = f[-1]
  if (bad = names.find { |x| x !~ /\A[a-z]{1,16}\z/ })
    err.call("bad name"); next
  end
  unless amt =~ /\A\d+(\.\d{1,2})?\z/ && (cmd == "OPEN" || cents(amt) > 0)
    err.call("bad amount"); next
  end
  c = cents(amt)
  if cmd == "OPEN"
    if accts.key?(names[0])
      err.call("account #{names[0]} exists"); next
    end
    accts[names[0]] = Acct.new(0, c, 0, 0, 0)
    next
  end
  if (m = names.find { |x| !accts.key?(x) })
    err.call("no account #{m}"); next
  end
  if cmd == "TRANSFER" && names[0] == names[1]
    err.call("same account"); next
  end
  a = accts[names[0]]
  if cmd == "DEPOSIT"
    change.call(a, c)
    a.txns += 1
  else
    if a.bal - c < -a.limit
      err.call("insufficient funds in #{names[0]}"); next
    end
    change.call(a, -c)
    a.txns += 1
    a.outs += 1
    if cmd == "TRANSFER"
      b = accts[names[1]]
      change.call(b, c)
      b.txns += 1
    end
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |k, v| [-v.bal, k.b] }.each do |k, v|
    puts format("%-16s %12s %12s %5d", k, money(v.bal), money(v.low), v.txns)
  end
  puts "total: #{money(accts.values.sum(&:bal))}"
end
