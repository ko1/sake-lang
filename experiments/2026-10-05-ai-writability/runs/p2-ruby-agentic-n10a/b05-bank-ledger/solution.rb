def money(c)
  (c < 0 ? "-" : "") + format("%d.%02d", c.abs / 100, c.abs % 100)
end

def cents(s)
  w, f = s.split(".")
  w.to_i * 100 + (f ? (f + "0")[0, 2].to_i : 0)
end

Acct = Struct.new(:bal, :limit, :low, :txns, :outs)
accts = {}
month = 0
FIELDS = {"OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1}

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  cmd = f[0]
  err = nil
  if !FIELDS.key?(cmd) then err = "unknown command"
  elsif f.size != FIELDS[cmd] then err = "wrong field count"
  end
  names = []
  amt = nil
  unless err || cmd == "MONTHEND"
    case cmd
    when "TRANSFER" then names = [f[1], f[2]]; amt = f[3]
    else names = [f[1]]; amt = f[2]
    end
    if names.any? { |x| x !~ /\A[a-z]{1,16}\z/ }
      err = "bad name"
    elsif amt !~ /\A\d+(\.\d{1,2})?\z/ || (cmd != "OPEN" && cents(amt) == 0)
      err = "bad amount"
    elsif cmd == "OPEN"
      err = "account #{names[0]} exists" if accts.key?(names[0])
    else
      names.each { |x| (err = "no account #{x}"; break) unless accts.key?(x) }
      err ||= "same account" if cmd == "TRANSFER" && names[0] == names[1]
      if !err && cmd != "DEPOSIT" && accts[names[0]].bal - cents(amt) < -accts[names[0]].limit
        err = "insufficient funds in #{names[0]}"
      end
    end
  end
  if err
    puts "line #{n}: error: #{err}"
    next
  end
  upd = lambda do |a, d|
    a.bal += d
    a.low = a.bal if a.bal < a.low
  end
  case cmd
  when "OPEN"
    accts[names[0]] = Acct.new(0, cents(amt), 0, 0, 0)
  when "DEPOSIT"
    a = accts[names[0]]
    upd.call(a, cents(amt))
    a.txns += 1
  when "WITHDRAW"
    a = accts[names[0]]
    upd.call(a, -cents(amt))
    a.txns += 1
    a.outs += 1
  when "TRANSFER"
    a = accts[names[0]]
    b = accts[names[1]]
    upd.call(a, -cents(amt))
    upd.call(b, cents(amt))
    a.txns += 1
    b.txns += 1
    a.outs += 1
  when "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |nm|
      a = accts[nm]
      if a.bal < 0
        ch = (-a.bal * 15 + 999) / 1000
        if ch != 0
          upd.call(a, -ch)
          puts "#{nm} interest -#{money(ch)}"
        end
      elsif a.bal > 0
        ad = a.bal * 25 / 10000
        if ad != 0
          upd.call(a, ad)
          puts "#{nm} interest +#{money(ad)}"
        end
      end
      if a.outs > 4
        upd.call(a, -200)
        puts "#{nm} fee -2.00"
      end
      a.outs = 0
    end
  end
end

if accts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accts.sort_by { |k, a| [-a.bal, k.b] }.each do |k, a|
    puts format("%-16s %12s %12s %5d", k, money(a.bal), money(a.low), a.txns)
  end
  puts "total: #{money(accts.values.sum(&:bal))}"
end
