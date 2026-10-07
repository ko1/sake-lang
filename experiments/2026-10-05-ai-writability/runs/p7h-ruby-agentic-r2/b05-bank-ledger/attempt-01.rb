#!/usr/bin/env ruby

def parse_money(str)
  return nil unless str =~ /^(\d+(?:\.\d{1,2})?)$/
  Float($1)
end

def format_money(amount)
  format("%.2f", amount)
end

def valid_name?(name)
  name =~ /^[a-z]{1,16}$/
end

class Account
  attr_accessor :balance, :limit, :lowest_balance, :transaction_count
  attr_accessor :withdrawals_since_monthend

  def initialize(limit)
    @balance = 0.0
    @limit = limit
    @lowest_balance = 0.0
    @transaction_count = 0
    @withdrawals_since_monthend = 0
  end
end

accounts = {}
month = 0

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp

  next if line.strip.empty?

  fields = line.split(/\s+/)
  command = fields[0]

  # Check command
  unless %w[OPEN DEPOSIT WITHDRAW TRANSFER MONTHEND].include?(command)
    puts "line #{line_no}: error: unknown command"
    next
  end

  if command == "OPEN"
    if fields.length != 3
      puts "line #{line_no}: error: wrong field count"
      next
    end

    name, limit_str = fields[1], fields[2]

    unless valid_name?(name)
      puts "line #{line_no}: error: bad name"
      next
    end

    limit = parse_money(limit_str)
    if limit.nil?
      puts "line #{line_no}: error: bad amount"
      next
    end

    if accounts[name]
      puts "line #{line_no}: error: account #{name} exists"
      next
    end

    accounts[name] = Account.new(limit)

  elsif command == "DEPOSIT"
    if fields.length != 3
      puts "line #{line_no}: error: wrong field count"
      next
    end

    name, amount_str = fields[1], fields[2]

    unless valid_name?(name)
      puts "line #{line_no}: error: bad name"
      next
    end

    amount = parse_money(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_no}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_no}: error: no account #{name}"
      next
    end

    accounts[name].balance += amount
    accounts[name].lowest_balance = [accounts[name].lowest_balance, accounts[name].balance].min
    accounts[name].transaction_count += 1

  elsif command == "WITHDRAW"
    if fields.length != 3
      puts "line #{line_no}: error: wrong field count"
      next
    end

    name, amount_str = fields[1], fields[2]

    unless valid_name?(name)
      puts "line #{line_no}: error: bad name"
      next
    end

    amount = parse_money(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_no}: error: bad amount"
      next
    end

    unless accounts[name]
      puts "line #{line_no}: error: no account #{name}"
      next
    end

    if accounts[name].balance - amount < -accounts[name].limit
      puts "line #{line_no}: error: insufficient funds in #{name}"
      next
    end

    accounts[name].balance -= amount
    accounts[name].lowest_balance = [accounts[name].lowest_balance, accounts[name].balance].min
    accounts[name].transaction_count += 1
    accounts[name].withdrawals_since_monthend += 1

  elsif command == "TRANSFER"
    if fields.length != 4
      puts "line #{line_no}: error: wrong field count"
      next
    end

    from_name, to_name, amount_str = fields[1], fields[2], fields[3]

    unless valid_name?(from_name)
      puts "line #{line_no}: error: bad name"
      next
    end

    unless valid_name?(to_name)
      puts "line #{line_no}: error: bad name"
      next
    end

    amount = parse_money(amount_str)
    if amount.nil? || amount <= 0
      puts "line #{line_no}: error: bad amount"
      next
    end

    unless accounts[from_name]
      puts "line #{line_no}: error: no account #{from_name}"
      next
    end

    unless accounts[to_name]
      puts "line #{line_no}: error: no account #{to_name}"
      next
    end

    if from_name == to_name
      puts "line #{line_no}: error: same account"
      next
    end

    if accounts[from_name].balance - amount < -accounts[from_name].limit
      puts "line #{line_no}: error: insufficient funds in #{from_name}"
      next
    end

    accounts[from_name].balance -= amount
    accounts[from_name].lowest_balance = [accounts[from_name].lowest_balance, accounts[from_name].balance].min
    accounts[from_name].transaction_count += 1
    accounts[from_name].withdrawals_since_monthend += 1

    accounts[to_name].balance += amount
    accounts[to_name].lowest_balance = [accounts[to_name].lowest_balance, accounts[to_name].balance].min
    accounts[to_name].transaction_count += 1

  elsif command == "MONTHEND"
    if fields.length != 1
      puts "line #{line_no}: error: wrong field count"
      next
    end

    month += 1
    puts "== month #{month} =="

    accounts.each do |name, account|
      # Calculate interest
      if account.balance < 0
        # Charge 1.5% of overdrawn amount, rounded UP
        overdrawn = -account.balance
        interest = (overdrawn * 0.015 * 100).ceil / 100.0
        if interest > 0
          puts "#{name} interest -#{format_money(interest)}"
          account.balance -= interest
          account.lowest_balance = [account.lowest_balance, account.balance].min
        end
      elsif account.balance > 0
        # Add 0.25% of balance, rounded DOWN
        interest = (account.balance * 0.0025 * 100).floor / 100.0
        if interest > 0
          puts "#{name} interest +#{format_money(interest)}"
          account.balance += interest
          account.lowest_balance = [account.lowest_balance, account.balance].min
        end
      end

      # Calculate fee
      if account.withdrawals_since_monthend > 4
        puts "#{name} fee -2.00"
        account.balance -= 2.00
        account.lowest_balance = [account.lowest_balance, account.balance].min
      end

      # Reset withdrawal counter
      account.withdrawals_since_monthend = 0
    end
  end
end

if accounts.empty?
  puts "no accounts"
else
  # Sort by balance descending, then by name ascending
  sorted = accounts.sort_by { |name, account| [-account.balance, name] }

  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  total_balance = 0.0
  sorted.each do |name, account|
    puts format("%-16s %12s %12s %5d", name, format_money(account.balance),
                format_money(account.lowest_balance), account.transaction_count)
    total_balance += account.balance
  end

  puts "total: #{format_money(total_balance)}"
end
