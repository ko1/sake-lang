class LedgerError < StandardError; end

class Account
  attr_reader :savings, :name, :limit, :balance, :lowest, :txns, :debits

  def initialize(name, limit, savings = false)
    @savings = savings
    @name = name
    @limit = limit
    @balance = 0
    @lowest = 0
    @txns = 0
    @debits = 0
  end

  def change(amount, txn: true, debit: false)
    @balance += amount
    @lowest = @balance if @balance < @lowest
    @txns += 1 if txn
    @debits += 1 if debit
  end

  def can_pay?(amount) = @balance - amount >= -@limit
  def new_month = @debits = 0
end

def money(c) = format("%s%d.%02d", c < 0 ? "-" : "", c.abs / 100, c.abs % 100)

def amount(s, allow_zero: false)
  m = s.match(/\A(\d+)(?:\.(\d\d?))?\z/) or raise LedgerError, "bad amount"
  c = m[1].to_i * 100 + (m[2] || "").ljust(2, "0").to_i
  raise LedgerError, "bad amount" if c == 0 && !allow_zero
  c
end

def lookup(accounts, n) = accounts[n] || raise(LedgerError, "no account #{n}")

def check_name(s) = s.match?(/\A[a-z]{1,16}\z/) ? s : raise(LedgerError, "bad name")

ARITY = { "OPEN" => 3, "DEPOSIT" => 3, "WITHDRAW" => 3, "TRANSFER" => 4, "MONTHEND" => 1 }.freeze

accounts = {}
month = 0
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    arity = ARITY[f[0]] or raise LedgerError, "unknown command"
    raise LedgerError, "wrong field count" unless f.size == arity || (f[0] == "OPEN" && f.size == 4)
    case f[0]
    when "OPEN"
      name = check_name(f[1])
      limit = amount(f[2], allow_zero: true)
      kind = f[3] || "checking"
      raise LedgerError, "bad kind" unless %w[checking savings].include?(kind)
      raise LedgerError, "bad limit" if kind == "savings" && limit != 0
      raise LedgerError, "account #{name} exists" if accounts[name]
      accounts[name] = Account.new(name, limit, kind == "savings")
    when "DEPOSIT", "WITHDRAW"
      name = check_name(f[1])
      amt = amount(f[2])
      a = lookup(accounts, name)
      if f[0] == "DEPOSIT"
        a.change(amt)
      else
        raise LedgerError, "insufficient funds in #{name}" unless a.can_pay?(amt)
        a.change(-amt, debit: true)
      end
    when "TRANSFER"
      from = check_name(f[1])
      to = check_name(f[2])
      amt = amount(f[3])
      a = lookup(accounts, from)
      b = lookup(accounts, to)
      raise LedgerError, "same account" if a.equal?(b)
      raise LedgerError, "insufficient funds in #{from}" unless a.can_pay?(amt)
      a.change(-amt, debit: true)
      b.change(amt)
    when "MONTHEND"
      month += 1
      puts "== month #{month} =="
      accounts.keys.sort.each do |n|
        a = accounts[n]
        if a.balance < 0
          charge = (-a.balance * 15 + 999) / 1000
          a.change(-charge, txn: false)
          puts "#{n} interest #{money(-charge)}" if charge > 0
        elsif a.balance > 0
          gain = a.balance * (a.savings ? 50 : 25) / 10_000
          a.change(gain, txn: false)
          puts "#{n} interest +#{money(gain)}" if gain > 0
        end
        if a.debits > (a.savings ? 2 : 4)
          a.change(-200, txn: false)
          puts "#{n} fee -2.00"
        end
        a.new_month
      end
    end
  rescue LedgerError => e
    puts "line #{lineno}: error: #{e.message}"
  end
end

if accounts.empty?
  puts "no accounts"
else
  puts format("%-16s %12s %12s %5s", "account", "balance", "lowest", "txns")
  accounts.values.sort_by { |a| [a.savings ? 1 : 0, -a.balance, a.name] }.each do |a|
    puts format("%-16s %12s %12s %5d", a.savings ? "#{a.name}*" : a.name, money(a.balance), money(a.lowest), a.txns)
  end
  puts "total: #{money(accounts.values.sum(&:balance))}"
  sv = accounts.values.select(&:savings)
  puts "savings total: #{money(sv.sum(&:balance))}" unless sv.empty?
end
