# Apply a batch of transfers between accounts; failed transfers roll back and are reported.
class InsufficientFunds < StandardError
  attr_reader :account, :needed

  def initialize(message, account, needed)
    super(message)
    @account = account
    @needed = needed
  end
end

class AccountNotFound < StandardError
  attr_reader :id

  def initialize(message, id)
    super(message)
    @id = id
  end
end

class AccountFrozen < StandardError
  attr_reader :id

  def initialize(message, id)
    super(message)
    @id = id
  end
end

class LimitExceeded < StandardError
  attr_reader :limit

  def initialize(message, limit)
    super(message)
    @limit = limit
  end
end

class Account
  attr_reader :id, :owner
  attr_accessor :balance, :frozen

  def initialize(id, owner, balance, frozen)
    @id = id
    @owner = owner
    @balance = balance
    @frozen = frozen
  end

  def withdraw(amount)
    raise AccountFrozen.new("account #{@id} is frozen", @id) if @frozen
    if @balance < amount
      raise InsufficientFunds.new("#{@owner} is short by #{amount - @balance}", @id, amount - @balance)
    end
    @balance -= amount
  end

  def deposit(amount)
    raise AccountFrozen.new("account #{@id} is frozen", @id) if @frozen
    @balance += amount
  end
end

class Bank
  attr_reader :accounts, :journal
  attr_accessor :daily_limit

  def initialize(accounts, journal, daily_limit)
    @accounts = accounts
    @journal = journal
    @daily_limit = daily_limit
  end

  def find(id)
    @accounts[id] or raise AccountNotFound.new("no account #{id}", id)
  end

  def transfer(from_id, to_id, amount)
    raise ArgumentError, "amount must be positive" if amount <= 0
    raise LimitExceeded.new("#{amount} exceeds limit #{@daily_limit}", @daily_limit) if amount > @daily_limit
    src = find(from_id)
    dst = find(to_id)
    withdrawn = false
    begin
      src.withdraw(amount)
      withdrawn = true
      dst.deposit(amount)
      @journal << [from_id, to_id, amount]
    rescue AccountFrozen
      src.balance += amount if withdrawn
      raise
    end
  end
end

def describe_error(e)
  case e
  when InsufficientFunds then "insufficient funds (#{e.needed} more needed)"
  when AccountNotFound then "unknown account #{e.id}"
  when AccountFrozen then "frozen account #{e.id}"
  when LimitExceeded then "over the limit of #{e.limit}"
  when ArgumentError then "invalid amount"
  end
end

accounts = {}
[["A1", "ann", 500], ["B2", "ben", 120], ["C3", "cid", 0], ["D4", "dee", 900]].each do |id, owner, bal|
  accounts[id] = Account.new(id, owner, bal, false)
end
accounts["C3"].frozen = true
bank = Bank.new(accounts, [], 1000)

requests = [
  ["A1", "B2", 200], ["B2", "A1", 500], ["A1", "C3", 50], ["Z9", "A1", 10],
  ["D4", "A1", 1500], ["D4", "B2", 0], ["D4", "B2", 300], ["B2", "D4", 620]
]

failures = Hash.new(0)
requests.each.with_index(1) do |(from, to, amount), n|
  label = format("%2d. %s -> %s %5d", n, from, to, amount)
  begin
    bank.transfer(from, to, amount)
    puts "#{label}  ok"
  rescue InsufficientFunds, AccountNotFound, AccountFrozen, LimitExceeded, ArgumentError => e
    reason = describe_error(e)
    failures[reason.split(" ").first] += 1
    puts "#{label}  FAILED: #{reason}"
  end
end

puts "balances:"
total = 0
accounts.each do |id, acct|
  total += acct.balance
  flag = acct.frozen ? " (frozen)" : ""
  puts format("  %s %-4s %6d%s", id, acct.owner, acct.balance, flag)
end
puts "total #{total}, journal entries #{bank.journal.size}"
puts "failure kinds: #{failures.keys.sort.map { |k| "#{k}=#{failures[k]}" }.join(", ")}"
