Acct = Struct.new(:limit, :bal, :low, :txns, :outs)

def cents(s)
  i, f = s.split(".")
  i.to_i * 100 + (f || "").ljust(2, "0").to_i
end

def money(c)
  (c < 0 ? "-" : "") + format("%d.%02d", c.abs / 100, c.abs % 100)
end

AMT = /\A\d+(\.\d{1,2})?\z/
accts = {}
month = 0

change = lambda do |a, d|
  a.bal += d
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |raw, no|
  f = raw.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  err = ->(m) { puts "line #{no}: error: #{m}" }
  cmd = f[0]
  arity = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }[cmd]
  if arity.nil? then err.("unknown command"); next end
  if f.size != arity then err.("wrong field count"); next end
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.sort_by { |n, _| n.b }.each do |n, a|
      if a.bal < 0
        ch = (15 * -a.bal + 999) / 1000
        if ch > 0
          change.(a, -ch)
          puts "#{n} interest -#{money(ch)}"
        end
      elsif a.bal > 0
        ch = 25 * a.bal / 10000
        if ch > 0
          change.(a, ch)
          puts "#{n} interest +#{money(ch)}"
        end
      end
      if a.outs > 4
        change.(a, -200)
        puts "#{n} fee -2.00"
      end
      a.outs = 0
    end
    next
  end
  names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
  amt = f[-1]
  if (bad = names.find { |n| n !~ /\A[a-z]{1,16}\z/ }) then err.("bad name"); next end
  if amt !~ AMT || (cmd != "OPEN" && cents(amt) == 0) then err.("bad amount"); next end
  c = cents(amt)
  if cmd == "OPEN"
    if accts.key?(names[0]) then err.("account #{names[0]} exists"); next end
    accts[names[0]] = Acct.new(c, 0, 0, 0, 0)
    next
  end
  if (m = names.find { |n| !accts.key?(n) }) then err.("no account #{m}"); next end
  case cmd
  when "DEPOSIT"
    a = accts[names[0]]
    change.(a, c)
    a.txns += 1
  when "WITHDRAW"
    a = accts[names[0]]
    if a.bal - c < -a.limit then err.("insufficient funds in #{names[0]}"); next end
    change.(a, -c)
    a.txns += 1
    a.outs += 1
  when "TRANSFER"
    if names[0] == names[1] then err.("same account"); next end
    a = accts[names[0]]
    b = accts[names[1]]
    if a.bal - c < -a.limit then err.("insufficient funds in #{names[0]}"); next end
    change.(a, -c)
    change.(b, c)
    a.txns += 1
    b.txns += 1
    a.outs += 1
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
