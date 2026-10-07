def is_valid_name?(name)
  name =~ /^[a-z]{1,16}$/
end

def is_valid_amount?(amount)
  amount =~ /^\d+(\.\d{1,2})?$/ && amount.to_f > 0
end

def is_valid_limit?(limit)
  limit =~ /^\d+(\.\d{1,2})?$/
end

def parse_amount(amount)
  amount.to_f
end

def format_money(val)
  format("%.2f", val)
end

accounts = {}
month_num = 0

$stdin.each_line.with_index(1) do |line, line_num|
  line = line.chomp
  next if line.strip.empty?

  fields = line.split(/\s+/)
  next if fields.empty?

  command = fields[0]

  unless ['OPEN', 'DEPOSIT', 'WITHDRAW', 'TRANSFER', 'MONTHEND'].include?(command)
    puts "line #{line_num}: error: unknown command"
    next
  end

  case command
  when 'OPEN'
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    limit = fields[2]

    unless is_valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless is_valid_limit?(limit)
      puts "line #{line_num}: error: bad amount"
      next
    end

    if accounts[name]
      puts "line #{line_num}: error: account #{name} exists"
      next
    end

    accounts[name] = {
      balance: 0.0,
      limit: parse_amount(limit),
      lowest: 0.0,
      txns: 0,
      withdrawals_and_transfers_out: 0
    }

  when 'DEPOSIT'
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    amount = fields[2]

    unless is_valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless is_valid_amount?(amount)
      puts "line #{line_num}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount_f = parse_amount(amount)
    accounts[name][:balance] += amount_f
    accounts[name][:txns] += 1
    if accounts[name][:balance] < accounts[name][:lowest]
      accounts[name][:lowest] = accounts[name][:balance]
    end

  when 'WITHDRAW'
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    amount = fields[2]

    unless is_valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless is_valid_amount?(amount)
      puts "line #{line_num}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount_f = parse_amount(amount)
    new_balance = accounts[name][:balance] - amount_f

    if new_balance < -accounts[name][:limit]
      puts "line #{line_num}: error: insufficient funds in #{name}"
      next
    end

    accounts[name][:balance] = new_balance
    accounts[name][:txns] += 1
    accounts[name][:withdrawals_and_transfers_out] += 1
    if accounts[name][:balance] < accounts[name][:lowest]
      accounts[name][:lowest] = accounts[name][:balance]
    end

  when 'TRANSFER'
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    from = fields[1]
    to = fields[2]
    amount = fields[3]

    unless is_valid_name?(from)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless is_valid_name?(to)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless is_valid_amount?(amount)
      puts "line #{line_num}: error: bad amount"
      next
    end

    unless accounts[from]
      puts "line #{line_num}: error: no account #{from}"
      next
    end

    unless accounts[to]
      puts "line #{line_num}: error: no account #{to}"
      next
    end

    if from == to
      puts "line #{line_num}: error: same account"
      next
    end

    amount_f = parse_amount(amount)
    new_balance = accounts[from][:balance] - amount_f

    if new_balance < -accounts[from][:limit]
      puts "line #{line_num}: error: insufficient funds in #{from}"
      next
    end

    accounts[from][:balance] = new_balance
    accounts[to][:balance] += amount_f
    accounts[from][:txns] += 1
    accounts[to][:txns] += 1
    accounts[from][:withdrawals_and_transfers_out] += 1

    if accounts[from][:balance] < accounts[from][:lowest]
      accounts[from][:lowest] = accounts[from][:balance]
    end
    if accounts[to][:balance] < accounts[to][:lowest]
      accounts[to][:lowest] = accounts[to][:balance]
    end

  when 'MONTHEND'
    if fields.length != 1
      puts "line #{line_num}: error: wrong field count"
      next
    end

    month_num += 1
    puts "== month #{month_num} =="

    accounts.keys.sort.each do |name|
      account = accounts[name]

      if account[:balance] < 0
        overdrawn = -account[:balance]
        interest_raw = overdrawn * 0.015
        interest = (interest_raw * 100).ceil / 100.0
        if interest > 0
          account[:balance] -= interest
          puts "#{name} interest -#{format_money(interest)}"
        end
      else
        interest_raw = account[:balance] * 0.0025
        interest = (interest_raw * 100).floor / 100.0
        if interest > 0
          account[:balance] += interest
          puts "#{name} interest +#{format_money(interest)}"
        end
      end

      if account[:balance] < account[:lowest]
        account[:lowest] = account[:balance]
      end

      if account[:withdrawals_and_transfers_out] > 4
        account[:balance] -= 2.00
        puts "#{name} fee -2.00"
      end

      if account[:balance] < account[:lowest]
        account[:lowest] = account[:balance]
      end

      account[:withdrawals_and_transfers_out] = 0
    end
  end
end

if accounts.empty?
  puts "no accounts"
else
  sorted = accounts.sort_by do |name, account|
    [-account[:balance], name]
  end

  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")

  total = 0.0
  sorted.each do |name, account|
    puts format("%-16s %12s %12s %5d", name, format_money(account[:balance]), format_money(account[:lowest]), account[:txns])
    total += account[:balance]
  end

  puts "total: #{format_money(total)}"
end
