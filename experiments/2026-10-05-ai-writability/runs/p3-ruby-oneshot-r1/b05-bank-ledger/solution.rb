def money(c)
  s = c < 0 ? "-" : ""
  a = c.abs
  format("%s%d.%02d", s, a / 100, a % 100)
end

def cents(s)
  return nil unless s.match?(/\A\d+(\.\d{1,2})?\z/)
  i, f = s.split(".")
  i.to_i * 100 + (f || "").ljust(2, "0").to_i
end

acc = {}
month = 0

change = lambda do |a, d|
  a[:bal] += d
  a[:low] = a[:bal] if a[:bal] < a[:low]
end

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(" ")
  next if f.empty?
  sizes = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }
  cmd = f[0]
  err = nil
  if !sizes.key?(cmd) then err = "unknown command"
  elsif f.size != sizes[cmd] then err = "wrong field count"
  end
  if err.nil? && cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    acc.keys.sort_by(&:b).each do |n|
      a = acc[n]
      if a[:bal] < 0
        ch = (-a[:bal] * 15 + 999) / 1000
        if ch > 0
          change.call(a, -ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a[:bal] > 0
        ad = a[:bal] * 25 / 10000
        if ad > 0
          change.call(a, ad)
          puts "#{n} interest +#{money(ad)}"
        end
      end
      if a[:out] > 4
        change.call(a, -200)
        puts "#{n} fee -2.00"
      end
      a[:out] = 0
    end
    next
  end
  if err.nil?
    names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
    err = "bad name" unless names.all? { |n| n.match?(/\A[a-z]{1,16}\z/) }
  end
  amt = nil
  if err.nil?
    amt = cents(f[-1])
    err = "bad amount" if amt.nil? || (cmd != "OPEN" && amt <= 0)
  end
  if err.nil?
    if cmd == "OPEN"
      err = "account #{f[1]} exists" if acc.key?(f[1])
    else
      names.each do |n|
        unless acc.key?(n)
          err = "no account #{n}"
          break
        end
      end
      err = "same account" if err.nil? && cmd == "TRANSFER" && f[1] == f[2]
      if err.nil? && cmd != "DEPOSIT"
        a = acc[f[1]]
        err = "insufficient funds in #{f[1]}" if a[:bal] - amt < -a[:limit]
      end
    end
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "OPEN"
    acc[f[1]] = { bal: 0, low: 0, limit: amt, txns: 0, out: 0 }
  when "DEPOSIT"
    a = acc[f[1]]
    change.call(a, amt)
    a[:txns] += 1
  when "WITHDRAW"
    a = acc[f[1]]
    change.call(a, -amt)
    a[:txns] += 1
    a[:out] += 1
  when "TRANSFER"
    a = acc[f[1]]
    b = acc[f[2]]
    change.call(a, -amt)
    a[:txns] += 1
    a[:out] += 1
    change.call(b, amt)
    b[:txns] += 1
  end
end
if acc.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  acc.sort_by { |n, a| [-a[:bal], n.b] }.each do |n, a|
    puts format("%-16s %12s %12s %5d", n, money(a[:bal]), money(a[:low]), a[:txns])
  end
  puts "total: #{money(acc.values.sum { |a| a[:bal] })}"
end
