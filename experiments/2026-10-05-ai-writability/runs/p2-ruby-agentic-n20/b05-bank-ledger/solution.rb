def money(c)
  s = format("%d.%02d", c.abs / 100, c.abs % 100)
  c < 0 ? "-" + s : s
end

def cents(s)
  a, b = s.split(".")
  a.to_i * 100 + (b ? (b.size == 1 ? b.to_i * 10 : b.to_i) : 0)
end

AMT = /\A\d+(\.\d{1,2})?\z/
NAME = /\A[a-z]{1,16}\z/

Acct = Struct.new(:bal, :limit, :low, :txns, :outs)
acc = {}
month = 0

change = lambda do |a, delta|
  a.bal += delta
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  counts = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }
  err = nil
  if !counts.key?(cmd) then err = "unknown command"
  elsif f.size != counts[cmd] then err = "wrong field count"
  end
  unless err
    case cmd
    when "OPEN", "DEPOSIT", "WITHDRAW"
      name, amt = f[1], f[2]
      if name !~ NAME then err = "bad name"
      elsif amt !~ AMT || (cmd != "OPEN" && cents(amt) == 0) then err = "bad amount"
      elsif cmd == "OPEN" && acc.key?(name) then err = "account #{name} exists"
      elsif cmd != "OPEN" && !acc.key?(name) then err = "no account #{name}"
      elsif cmd == "WITHDRAW" && acc[name].bal - cents(amt) < -acc[name].limit
        err = "insufficient funds in #{name}"
      end
    when "TRANSFER"
      a, b, amt = f[1], f[2], f[3]
      if a !~ NAME || b !~ NAME then err = "bad name"
      elsif amt !~ AMT || cents(amt) == 0 then err = "bad amount"
      elsif !acc.key?(a) then err = "no account #{a}"
      elsif !acc.key?(b) then err = "no account #{b}"
      elsif a == b then err = "same account"
      elsif acc[a].bal - cents(amt) < -acc[a].limit then err = "insufficient funds in #{a}"
      end
    end
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "OPEN"
    acc[f[1]] = Acct.new(0, cents(f[2]), 0, 0, 0)
  when "DEPOSIT"
    a = acc[f[1]]
    change.call(a, cents(f[2]))
    a.txns += 1
  when "WITHDRAW"
    a = acc[f[1]]
    change.call(a, -cents(f[2]))
    a.txns += 1
    a.outs += 1
  when "TRANSFER"
    a = acc[f[1]]
    b = acc[f[2]]
    c = cents(f[3])
    change.call(a, -c)
    change.call(b, c)
    a.txns += 1
    b.txns += 1
    a.outs += 1
  when "MONTHEND"
    month += 1
    puts "== month #{month} =="
    acc.keys.sort_by(&:b).each do |n|
      a = acc[n]
      if a.bal < 0
        ch = (-a.bal * 15 + 999) / 1000
        if ch != 0
          change.call(a, -ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a.bal > 0
        ad = a.bal * 25 / 10000
        if ad != 0
          change.call(a, ad)
          puts "#{n} interest +#{money(ad)}"
        end
      end
      if a.outs > 4
        change.call(a, -200)
        puts "#{n} fee -2.00"
      end
      a.outs = 0
    end
  end
end

if acc.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  acc.sort_by { |n, a| [-a.bal, n.b] }.each do |n, a|
    puts format("%-16s %12s %12s %5d", n, money(a.bal), money(a.low), a.txns)
  end
  puts "total: #{money(acc.values.sum(&:bal))}"
end
