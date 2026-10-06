def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 ? $2.ljust(2, "0").to_i : 0)
end

ARITY = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }.freeze
acc = {}
month = 0

change = lambda do |a, delta|
  a[:bal] += delta
  a[:low] = a[:bal] if a[:bal] < a[:low]
end

$stdin.each_line.with_index(1) do |raw, no|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  cmd = f[0]
  unless ARITY.key?(cmd)
    puts "line #{no}: error: unknown command"
    next
  end
  if f.size != ARITY[cmd]
    puts "line #{no}: error: wrong field count"
    next
  end
  if cmd == "MONTHEND"
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
        ch = a[:bal] * 25 / 10000
        if ch > 0
          change.call(a, ch)
          puts "#{n} interest +#{money(ch)}"
        end
      end
      if a[:outs] > 4
        change.call(a, -200)
        puts "#{n} fee -2.00"
      end
      a[:outs] = 0
    end
    next
  end
  names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
  amt_s = f[-1]
  err = nil
  err = "bad name" unless names.all? { |n| n =~ /\A[a-z]{1,16}\z/ }
  amt = nil
  unless err
    amt = cents(amt_s)
    err = "bad amount" if amt.nil? || (cmd != "OPEN" && amt == 0)
  end
  if !err && cmd == "OPEN"
    err = "account #{names[0]} exists" if acc.key?(names[0])
  elsif !err
    names.each do |n|
      unless acc.key?(n)
        err = "no account #{n}"
        break
      end
    end
    err ||= "same account" if cmd == "TRANSFER" && names[0] == names[1]
    if !err && cmd != "DEPOSIT"
      a = acc[names[0]]
      err = "insufficient funds in #{names[0]}" if a[:bal] - amt < -a[:limit]
    end
  end
  if err
    puts "line #{no}: error: #{err}"
    next
  end
  case cmd
  when "OPEN"
    acc[names[0]] = { bal: 0, low: 0, limit: amt, txns: 0, outs: 0 }
  when "DEPOSIT"
    a = acc[names[0]]
    change.call(a, amt)
    a[:txns] += 1
  when "WITHDRAW"
    a = acc[names[0]]
    change.call(a, -amt)
    a[:txns] += 1
    a[:outs] += 1
  when "TRANSFER"
    a = acc[names[0]]
    b = acc[names[1]]
    change.call(a, -amt)
    a[:txns] += 1
    a[:outs] += 1
    change.call(b, amt)
    b[:txns] += 1
  end
end

if acc.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  total = 0
  acc.sort_by { |n, a| [-a[:bal], n.b] }.each do |n, a|
    total += a[:bal]
    puts format("%-16s %12s %12s %5d", n, money(a[:bal]), money(a[:low]), a[:txns])
  end
  puts "total: #{money(total)}"
end
