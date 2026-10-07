require 'bigdecimal'

def parse_amount(str)
  if str.match?(/^\d+(\.\d{1,2})?$/)
    BigDecimal(str)
  else
    nil
  end
end

def format_money(value)
  # Ensure exactly 2 decimal places
  value_d = BigDecimal(value.to_s)
  format("%.2f", value_d)
end

def validate_name(name)
  name.match?(/^[a-z]{1,16}$/)
end

lines = STDIN.readlines
accounts = {}  # name -> {balance, limit, lowest, txn_count, txn_since_monthend}
month = 0

lines.each_with_index do |line, idx|
  line_num = idx + 1

  next if line.strip.empty?

  fields = line.split
  next if fields.empty?

  cmd = fields[0]

  unless %w[OPEN DEPOSIT WITHDRAW TRANSFER MONTHEND].include?(cmd)
    puts "line #{line_num}: error: unknown command"
    next
  end

  if cmd == "OPEN"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name, limit_str = fields[1], fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    limit = parse_amount(limit_str)
    if limit.nil?
      puts "line #{line_num}: error: bad amount"
      next
    end

    if accounts[name]
      puts "line #{line_num}: error: account #{name} exists"
      next
    end

    accounts[name] = {
      balance: BigDecimal(0),
      limit: limit,
      lowest: BigDecimal(0),
      txn_count: 0,
      txn_since_monthend: 0
    }

  elsif cmd == "DEPOSIT"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name, amount_str = fields[1], fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount = parse_amount(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_num}: error: bad amount"
      next
    end

    accounts[name][:balance] += amount
    accounts[name][:lowest] = accounts[name][:balance] if accounts[name][:balance] < accounts[name][:lowest]
    accounts[name][:txn_count] += 1
    accounts[name][:txn_since_monthend] += 1

  elsif cmd == "WITHDRAW"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name, amount_str = fields[1], fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount = parse_amount(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_num}: error: bad amount"
      next
    end

    # Check if allowed
    if accounts[name][:balance] - amount < -accounts[name][:limit]
      puts "line #{line_num}: error: insufficient funds in #{name}"
      next
    end

    accounts[name][:balance] -= amount
    accounts[name][:lowest] = accounts[name][:balance] if accounts[name][:balance] < accounts[name][:lowest]
    accounts[name][:txn_count] += 1
    accounts[name][:txn_since_monthend] += 1

  elsif cmd == "TRANSFER"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    from_name, to_name, amount_str = fields[1], fields[2], fields[3]

    unless validate_name(from_name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_name(to_name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless accounts[from_name]
      puts "line #{line_num}: error: no account #{from_name}"
      next
    end

    unless accounts[to_name]
      puts "line #{line_num}: error: no account #{to_name}"
      next
    end

    if from_name == to_name
      puts "line #{line_num}: error: same account"
      next
    end

    amount = parse_amount(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_num}: error: bad amount"
      next
    end

    # Check if allowed
    if accounts[from_name][:balance] - amount < -accounts[from_name][:limit]
      puts "line #{line_num}: error: insufficient funds in #{from_name}"
      next
    end

    accounts[from_name][:balance] -= amount
    accounts[from_name][:lowest] = accounts[from_name][:balance] if accounts[from_name][:balance] < accounts[from_name][:lowest]
    accounts[from_name][:txn_count] += 1
    accounts[from_name][:txn_since_monthend] += 1

    accounts[to_name][:balance] += amount
    accounts[to_name][:lowest] = accounts[to_name][:balance] if accounts[to_name][:balance] < accounts[to_name][:lowest]
    accounts[to_name][:txn_count] += 1
    accounts[to_name][:txn_since_monthend] += 1

  elsif cmd == "MONTHEND"
    month += 1
    puts "== month #{month} =="

    sorted_names = accounts.keys.sort

    sorted_names.each do |name|
      account = accounts[name]

      if account[:balance] < 0
        # Charge 1.5% of overdraft, rounded up
        overdraft = -account[:balance]
        interest = (overdraft * BigDecimal("0.015")).ceil(2)
        if interest > 0
          puts "#{name} interest -#{format_money(interest)}"
          account[:balance] -= interest
          account[:lowest] = account[:balance] if account[:balance] < account[:lowest]
        end
      elsif account[:balance] > 0
        # Add 0.25% of balance, rounded down
        interest = (account[:balance] * BigDecimal("0.0025")).floor(2)
        if interest > 0
          puts "#{name} interest +#{format_money(interest)}"
          account[:balance] += interest
          account[:lowest] = account[:balance] if account[:balance] < account[:lowest]
        end
      end

      # Check for fee
      if account[:txn_since_monthend] > 4
        puts "#{name} fee -2.00"
        account[:balance] -= BigDecimal("2.00")
        account[:lowest] = account[:balance] if account[:balance] < account[:lowest]
      end

      account[:txn_since_monthend] = 0
    end
  end
end

# Final output
if accounts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")

  sorted = accounts.sort_by do |name, account|
    [-account[:balance].to_f, name]
  end

  total_balance = BigDecimal(0)
  sorted.each do |name, account|
    puts format("%-16s %12s %12s %5d",
                name,
                format_money(account[:balance]),
                format_money(account[:lowest]),
                account[:txn_count])
    total_balance += account[:balance]
  end

  puts "total: #{format_money(total_balance)}"
end
