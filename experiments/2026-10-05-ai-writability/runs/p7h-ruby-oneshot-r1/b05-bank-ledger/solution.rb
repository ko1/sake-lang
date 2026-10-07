#!/usr/bin/env ruby

def parse_money(money_str)
  (money_str.to_f * 100).round.to_i
end

def format_money(cents)
  dollars = cents / 100
  remainder = (cents % 100).abs
  if cents < 0
    "-#{dollars.abs}.#{remainder.to_s.rjust(2, '0')}"
  else
    "#{dollars}.#{remainder.to_s.rjust(2, '0')}"
  end
end

def validate_name(name)
  name =~ /^[a-z]{1,16}$/
end

def validate_money(money_str)
  money_str =~ /^\d+(\.\d{1,2})?$/
end

accounts = {}
month = 0

STDIN.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.strip

  next if line.empty?

  fields = line.split(/\s+/)
  command = fields[0]

  if command == "OPEN"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    limit_str = fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_money(limit_str)
      puts "line #{line_num}: error: bad amount"
      next
    end

    if accounts[name]
      puts "line #{line_num}: error: account #{name} exists"
      next
    end

    limit = parse_money(limit_str)
    accounts[name] = {
      balance: 0,
      limit: limit,
      lowest: 0,
      txns: 0,
      withdrawals_since_month_end: 0
    }

  elsif command == "DEPOSIT"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    amount_str = fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_money(amount_str) || amount_str.to_f > 0
      puts "line #{line_num}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount = parse_money(amount_str)
    accounts[name][:balance] += amount
    accounts[name][:lowest] = [accounts[name][:lowest], accounts[name][:balance]].min
    accounts[name][:txns] += 1

  elsif command == "WITHDRAW"
    if fields.length != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    amount_str = fields[2]

    unless validate_name(name)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_money(amount_str) || amount_str.to_f > 0
      puts "line #{line_num}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_num}: error: no account #{name}"
      next
    end

    amount = parse_money(amount_str)
    if accounts[name][:balance] - amount < -accounts[name][:limit]
      puts "line #{line_num}: error: insufficient funds in #{name}"
      next
    end

    accounts[name][:balance] -= amount
    accounts[name][:lowest] = [accounts[name][:lowest], accounts[name][:balance]].min
    accounts[name][:txns] += 1
    accounts[name][:withdrawals_since_month_end] += 1

  elsif command == "TRANSFER"
    if fields.length != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    from = fields[1]
    to = fields[2]
    amount_str = fields[3]

    unless validate_name(from)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_name(to)
      puts "line #{line_num}: error: bad name"
      next
    end

    unless validate_money(amount_str) || amount_str.to_f > 0
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

    amount = parse_money(amount_str)
    if accounts[from][:balance] - amount < -accounts[from][:limit]
      puts "line #{line_num}: error: insufficient funds in #{from}"
      next
    end

    accounts[from][:balance] -= amount
    accounts[from][:lowest] = [accounts[from][:lowest], accounts[from][:balance]].min
    accounts[from][:txns] += 1
    accounts[from][:withdrawals_since_month_end] += 1

    accounts[to][:balance] += amount
    accounts[to][:lowest] = [accounts[to][:lowest], accounts[to][:balance]].min
    accounts[to][:txns] += 1

  elsif command == "MONTHEND"
    if fields.length != 1
      puts "line #{line_num}: error: wrong field count"
      next
    end

    month += 1
    puts "== month #{month} =="

    accounts.each do |name, account|
      if account[:balance] < 0
        overdrawn = -account[:balance]
        interest_cents = (overdrawn * 1.5 / 100.0).ceil
        if interest_cents > 0
          account[:balance] -= interest_cents
          account[:lowest] = [account[:lowest], account[:balance]].min
          puts "#{name} interest -#{format_money(interest_cents)}"
        end
      else
        interest_cents = (account[:balance] * 0.25 / 100.0).floor
        if interest_cents > 0
          account[:balance] += interest_cents
          account[:lowest] = [account[:lowest], account[:balance]].min
          puts "#{name} interest +#{format_money(interest_cents)}"
        end
      end

      if account[:withdrawals_since_month_end] > 4
        account[:balance] -= 200
        account[:lowest] = [account[:lowest], account[:balance]].min
        puts "#{name} fee -2.00"
      end

      account[:withdrawals_since_month_end] = 0
    end
  else
    puts "line #{line_num}: error: unknown command"
  end
end

if accounts.empty?
  puts "no accounts"
else
  sorted = accounts.sort do |a, b|
    balance_cmp = b[1][:balance] <=> a[1][:balance]
    balance_cmp.zero? ? a[0] <=> b[0] : balance_cmp
  end

  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  total_balance = 0
  sorted.each do |name, account|
    total_balance += account[:balance]
    puts format("%-16s %12s %12s %5d", name, format_money(account[:balance]),
                format_money(account[:lowest]), account[:txns])
  end

  puts "total: #{format_money(total_balance)}"
end
