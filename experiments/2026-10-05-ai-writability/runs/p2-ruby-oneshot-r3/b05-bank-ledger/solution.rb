def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

def money(c)
  sign = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", sign, c / 100, c % 100)
end

accts = {}
month = 0

change = lambda do |a, delta|
  a[:bal] += delta
  a[:low] = a[:bal] if a[:bal] < a[:low]
end

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.delete("\r").split(/ +/).reject(&:empty?)
  next if f.empty?
  err = lambda { |msg| puts "line #{no}: error: #{msg}" }
  cmd = f[0]
  counts = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }
  unless counts.key?(cmd)
    err.call("unknown command")
    next
  end
  if f.size != counts[cmd]
    err.call("wrong field count")
    next
  end

  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |name|
      a = accts[name]
      if a[:bal] < 0
        charge = (-a[:bal] * 15 + 999) / 1000
        if charge > 0
          change.call(a, -charge)
          puts "#{name} interest -#{money(charge)}"
        end
      elsif a[:bal] > 0
        gain = a[:bal] * 25 / 10000
        if gain > 0
          change.call(a, gain)
          puts "#{name} interest +#{money(gain)}"
        end
      end
      if a[:outs] > 4
        change.call(a, -200)
        puts "#{name} fee -2.00"
      end
      a[:outs] = 0
    end
    next
  end

  names = case cmd
          when "OPEN", "DEPOSIT", "WITHDRAW" then [f[1]]
          else [f[1], f[2]]
          end
  if (bad = names.find { |n| n !~ /\A[a-z]{1,16}\z/ })
    err.call("bad name")
    next
  end
  amt = cents(f.last)
  if amt.nil? || (cmd != "OPEN" && amt == 0)
    err.call("bad amount")
    next
  end

  if cmd == "OPEN"
    if accts.key?(f[1])
      err.call("account #{f[1]} exists")
      next
    end
    accts[f[1]] = { bal: 0, low: 0, txns: 0, outs: 0, limit: amt }
    next
  end

  if (missing = names.find { |n| !accts.key?(n) })
    err.call("no account #{missing}")
    next
  end

  case cmd
  when "DEPOSIT"
    a = accts[f[1]]
    change.call(a, amt)
    a[:txns] += 1
  when "WITHDRAW"
    a = accts[f[1]]
    if a[:bal] - amt < -a[:limit]
      err.call("insufficient funds in #{f[1]}")
      next
    end
    change.call(a, -amt)
    a[:txns] += 1
    a[:outs] += 1
  when "TRANSFER"
    if f[1] == f[2]
      err.call("same account")
      next
    end
    a = accts[f[1]]
    b = accts[f[2]]
    if a[:bal] - amt < -a[:limit]
      err.call("insufficient funds in #{f[1]}")
      next
    end
    change.call(a, -amt)
    change.call(b, amt)
    a[:txns] += 1
    a[:outs] += 1
    b[:txns] += 1
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |n, a| [-a[:bal], n.b] }.each do |n, a|
    puts format("%-16s %12s %12s %5d", n, money(a[:bal]), money(a[:low]), a[:txns])
  end
  puts "total: #{money(accts.values.sum { |a| a[:bal] })}"
end
