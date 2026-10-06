def money(c)
  a = c.abs
  format("%s%d.%02d", c < 0 ? "-" : "", a / 100, a % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
end

Acct = Struct.new(:bal, :limit, :low, :txns, :outs)
accts = {}
month = 0

change = lambda do |a, delta|
  a.bal += delta
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(" ")
  err = lambda { |m| puts "line #{no}: error: #{m}" }
  sizes = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }
  cmd = f[0]
  next err.call("unknown command") unless sizes.key?(cmd)
  next err.call("wrong field count") if f.size != sizes[cmd]
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |n|
      a = accts[n]
      if a.bal < 0
        ch = (-a.bal * 15 + 999) / 1000
        if ch > 0
          change.call(a, -ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a.bal > 0
        ch = a.bal * 25 / 10000
        if ch > 0
          change.call(a, ch)
          puts "#{n} interest +#{money(ch)}"
        end
      end
      if a.outs > 4
        change.call(a, -200)
        puts "#{n} fee -2.00"
      end
      a.outs = 0
    end
    next
  end
  names = cmd == "TRANSFER" ? [f[1], f[2]] : [f[1]]
  bad = names.find { |n| n !~ /\A[a-z]{1,16}\z/ }
  next err.call("bad name") if bad
  amt = cents(f[-1])
  next err.call("bad amount") if amt.nil? || (cmd != "OPEN" && amt == 0)
  if cmd == "OPEN"
    next err.call("account #{names[0]} exists") if accts.key?(names[0])
    accts[names[0]] = Acct.new(0, amt, 0, 0, 0)
    next
  end
  missing = names.find { |n| !accts.key?(n) }
  next err.call("no account #{missing}") if missing
  case cmd
  when "DEPOSIT"
    a = accts[names[0]]
    change.call(a, amt)
    a.txns += 1
  when "WITHDRAW"
    a = accts[names[0]]
    next err.call("insufficient funds in #{names[0]}") if a.bal - amt < -a.limit
    change.call(a, -amt)
    a.txns += 1
    a.outs += 1
  when "TRANSFER"
    next err.call("same account") if names[0] == names[1]
    a = accts[names[0]]
    b = accts[names[1]]
    next err.call("insufficient funds in #{names[0]}") if a.bal - amt < -a.limit
    change.call(a, -amt)
    change.call(b, amt)
    a.txns += 1
    a.outs += 1
    b.txns += 1
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |n, a| [-a.bal, n.b] }.each do |n, a|
    puts format("%-16s %12s %12s %5d", n, money(a.bal), money(a.low), a.txns)
  end
  puts "total: #{money(accts.values.sum(&:bal))}"
end
