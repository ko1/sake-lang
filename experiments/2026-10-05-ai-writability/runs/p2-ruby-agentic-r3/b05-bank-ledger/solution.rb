def money(c)
  s = c < 0 ? "-" : ""
  c = c.abs
  format("%s%d.%02d", s, c / 100, c % 100)
end

def cents(s)
  return nil unless s =~ /\A(\d+)(?:\.(\d{1,2}))?\z/
  $1.to_i * 100 + ($2 || "").ljust(2, "0").to_i
end

Acct = Struct.new(:limit, :bal, :low, :txns, :outs)
accts = {}
month = 0
ARGC = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }.freeze

change = lambda do |a, d|
  a.bal += d
  a.low = a.bal if a.bal < a.low
end

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  err = lambda { |m| puts "line #{no}: error: #{m}" }
  cmd = f[0]
  next err.("unknown command") unless ARGC.key?(cmd)
  next err.("wrong field count") if f.size != ARGC[cmd]
  if cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="
    accts.keys.sort_by(&:b).each do |n|
      a = accts[n]
      if a.bal < 0
        c = (-a.bal * 3 + 199) / 200
        if c > 0
          change.(a, -c)
          puts "#{n} interest #{money(-c)}"
        end
      elsif a.bal > 0
        c = a.bal / 400
        if c > 0
          change.(a, c)
          puts "#{n} interest +#{money(c)}"
        end
      end
      if a.outs > 4
        change.(a, -200)
        puts "#{n} fee -2.00"
      end
    end
    accts.each_value { |a| a.outs = 0 }
    next
  end
  names = cmd == "TRANSFER" ? f[1, 2] : [f[1]]
  next err.("bad name") unless names.all? { |n| n =~ /\A[a-z]{1,16}\z/ }
  amt = cents(f[-1])
  next err.("bad amount") if amt.nil? || (cmd != "OPEN" && amt == 0)
  case cmd
  when "OPEN"
    next err.("account #{names[0]} exists") if accts.key?(names[0])
    accts[names[0]] = Acct.new(amt, 0, 0, 0, 0)
  when "DEPOSIT"
    a = accts[names[0]]
    next err.("no account #{names[0]}") unless a
    change.(a, amt)
    a.txns += 1
  when "WITHDRAW"
    a = accts[names[0]]
    next err.("no account #{names[0]}") unless a
    next err.("insufficient funds in #{names[0]}") if a.bal - amt < -a.limit
    change.(a, -amt)
    a.txns += 1
    a.outs += 1
  when "TRANSFER"
    a = accts[names[0]]
    b = accts[names[1]]
    next err.("no account #{names[0]}") unless a
    next err.("no account #{names[1]}") unless b
    next err.("same account") if names[0] == names[1]
    next err.("insufficient funds in #{names[0]}") if a.bal - amt < -a.limit
    change.(a, -amt)
    change.(b, amt)
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
