class InsufficientFunds < StandardError
  attr_reader :account, :needed

  def initialize(message, account, needed)
    super(message)
    @account = account
    @needed = needed
  end
end

class UnknownAccount < StandardError
  attr_reader :id

  def initialize(message, id)
    super(message)
    @id = id
  end
end

class Account
  attr_reader :id, :owner, :kind
  attr_accessor :balance, :frozen

  def initialize(id, owner, kind, balance = 0, frozen = false)
    @id = id
    @owner = owner
    @kind = kind
    @balance = balance
    @frozen = frozen
  end

  def to_s = format("%-6s %-8s %-8s %10s", @id, @owner, @kind, cents(@balance))
end

def cents(n)
  sign = n < 0 ? "-" : ""
  m = n.abs
  "#{sign}#{m / 100}.#{(m % 100).to_s.rjust(2, "0")}"
end

class Bank
  attr_reader :accounts, :journal, :rates

  def initialize(accounts, journal, rates)
    @accounts = accounts
    @journal = journal
    @rates = rates
  end

  def find(id)
    acct = @accounts[id]
    raise UnknownAccount.new("no account #{id}", id) if acct.nil?
    acct
  end

  def open(id, owner, kind)
    acct = Account.new(id, owner, kind)
    @accounts[id] = acct
    acct
  end

  def record(kind, id, amount)
    @journal.push([kind, id, amount])
  end

  def deposit(id, amount)
    acct = find(id)
    acct.balance += amount
    record("dep", id, amount)
  end

  def withdraw(id, amount)
    acct = find(id)
    raise "account #{id} is frozen" if acct.frozen
    limit = acct.kind == "checking" ? -5000 : 0
    after = acct.balance - amount
    raise InsufficientFunds.new("insufficient funds in #{id}", id, amount) if after < limit
    acct.balance = after
    record("wd", id, amount)
  end

  def transfer(from, to, amount)
    find(to)
    withdraw(from, amount)
    deposit(to, amount)
  end

  def month_end
    @accounts.each do |id, acct|
      bal = acct.balance
      if bal < 0
        fee = 1500
        acct.balance = bal - fee
        record("fee", id, fee)
      else
        rate = @rates.fetch(acct.kind, 0)
        interest = bal * rate / 10000
        if interest > 0
          acct.balance = bal + interest
          record("int", id, interest)
        end
      end
    end
  end

  def total = @accounts.values.map(&:balance).sum
end

bank = Bank.new({}, [], { "savings" => 125, "checking" => 5 })
bank.open("A100", "alice", "checking")
bank.open("A101", "alice", "savings")
bank.open("B200", "bob", "checking")
bank.open("C300", "carol", "savings")

ops = [
  [:dep, "A100", "", 120000], [:dep, "A101", "", 500000], [:dep, "B200", "", 30000],
  [:dep, "C300", "", 75000], [:xfer, "A100", "B200", 45000], [:wd, "B200", "", 80000],
  [:wd, "B200", "", 2000], [:xfer, "C300", "D400", 100], [:wd, "C300", "", 90000],
  [:month, "", "", 0], [:freeze, "B200", "", 0], [:wd, "B200", "", 100],
  [:xfer, "A101", "A100", 250000], [:dep, "Z999", "", 5], [:month, "", "", 0],
  [:wd, "A100", "", 330000], [:month, "", "", 0]
]

failures = Hash.new(0)
step = 0
ops.each do |op, a, b, amount|
  step += 1
  begin
    case op
    in :dep then bank.deposit(a, amount)
    in :wd then bank.withdraw(a, amount)
    in :xfer then bank.transfer(a, b, amount)
    in :month then bank.month_end
    in :freeze then bank.find(a).frozen = true
    end
  rescue InsufficientFunds => e
    puts "step #{step}: #{e.message} (needed #{cents(e.needed)})"
    failures["funds"] += 1
  rescue UnknownAccount => e
    puts "step #{step}: unknown account #{e.id}"
    failures["unknown"] += 1
  rescue RuntimeError => e
    puts "step #{step}: #{e.message}"
    failures["other"] += 1
  end
end

puts "--- accounts"
bank.accounts.each_value { |acct| puts acct }
puts "total: #{cents(bank.total)}"

puts "--- journal by kind"
by_kind = bank.journal.group_by { |kind, _id, _amount| kind }
by_kind.each do |kind, entries|
  sum = entries.sum { |_k, _id, amount| amount }
  puts format("%-4s %3d entries %12s", kind, entries.size, cents(sum))
end

puts "--- failures"
failures.each { |k, n| puts "#{k}: #{n}" }

richest = bank.accounts.values.max_by(&:balance)
puts "richest: #{richest.owner} #{richest.id}" if richest
owners = Hash.new(0)
bank.accounts.each_value { |acct| owners[acct.owner] += acct.balance }
owners.sort_by { |_o, bal| -bal }.each { |o, bal| puts "#{o}: #{cents(bal)}" }
