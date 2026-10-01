class Opened
  attr_reader :seq, :account, :owner

  def initialize(seq, account, owner)
    @seq = seq
    @account = account
    @owner = owner
  end
end

class Deposited
  attr_reader :seq, :account, :amount

  def initialize(seq, account, amount)
    @seq = seq
    @account = account
    @amount = amount
  end
end

class Withdrawn
  attr_reader :seq, :account, :amount

  def initialize(seq, account, amount)
    @seq = seq
    @account = account
    @amount = amount
  end
end

class Transferred
  attr_reader :seq, :from, :to, :amount

  def initialize(seq, from, to, amount)
    @seq = seq
    @from = from
    @to = to
    @amount = amount
  end
end

class Closed
  attr_reader :seq, :account

  def initialize(seq, account)
    @seq = seq
    @account = account
  end
end

class Account
  attr_accessor :id, :owner, :balance, :status

  def initialize(id, owner, balance, status)
    @id = id
    @owner = owner
    @balance = balance
    @status = status
  end

  def to_s = format("%-3s %-5s %7d %s", @id, @owner, @balance, @status)
end

class Rejected < StandardError
  attr_reader :seq

  def initialize(message, seq)
    super(message)
    @seq = seq
  end
end

def open_account(state, id, seq)
  acct = state[id]
  raise Rejected.new("unknown account #{id}", seq) if !acct    
  raise Rejected.new("account #{id} is closed", seq) if acct.status == :closed
  acct
end

def apply(state, ev)
  seq = ev.seq
  case ev
  in Opened
    id = ev.account
    raise Rejected.new("duplicate account #{id}", seq) if state.key?(id)
    state[id] = Account.new(id, ev.owner, 0, :open)
  in Deposited
    acct = open_account(state, ev.account, seq)
    acct.balance += ev.amount
  in Withdrawn
    acct = open_account(state, ev.account, seq)
    raise Rejected.new("insufficient funds in #{acct.id}", seq) if acct.balance < ev.amount
    acct.balance -= ev.amount
  in Transferred
    src = open_account(state, ev.from, seq)
    dst = open_account(state, ev.to, seq)
    raise Rejected.new("insufficient funds in #{src.id}", seq) if src.balance < ev.amount
    src.balance -= ev.amount
    dst.balance += ev.amount
  in Closed
    acct = open_account(state, ev.account, seq)
    raise Rejected.new("balance not zero in #{acct.id}", seq) if acct.balance != 0
    acct.status = :closed
  end
end

def snapshot(state)
  state.transform_values(&:dup)
end

def replay(events, start_state, after_seq, rejected)
  state = snapshot(start_state)
  events.each do |ev|
    next if ev.seq <= after_seq
    begin
      apply(state, ev)
    rescue Rejected => e
      rejected << "##{e.seq} #{e.message}" if rejected
    end
  end
  state
end

def same_state?(a, b)
  return false if a.size != b.size
  a.all? { |id, acct| b[id] && acct.to_s == b[id].to_s }
end

log = [
  Opened.new(1, "A1", "ann"), Opened.new(2, "B2", "bob"), Deposited.new(3, "A1", 500),
  Withdrawn.new(4, "B2", 50), Deposited.new(5, "B2", 120), Transferred.new(6, "A1", "B2", 200),
  Opened.new(7, "C3", "cy"), Transferred.new(8, "B2", "C3", 320), Closed.new(9, "B2"),
  Deposited.new(10, "B2", 10), Opened.new(11, "A1", "amy"), Withdrawn.new(12, "C3", 20),
  Closed.new(13, "A1"), Transferred.new(14, "C3", "X9", 1)
]

rejected = []
full = replay(log, {}, 0, rejected)
puts "final state:"
full.each_value { |acct| puts "  #{acct}" }
puts "rejected events:"
rejected.each { puts "  #{it}" }

snapshots = { 0 => {} }
state = {}
log.each do |ev|
  apply(state, ev) rescue nil
  snapshots[ev.seq] = snapshot(state) if ev.seq % 5 == 0
end
snapshots.each do |at, snap|
  rebuilt = replay(log, snap, at, nil)
  total = rebuilt.sum { |id, acct| acct.balance }
  puts format("from snapshot @%-2d (%d accounts): total=%d consistent=%s", at, snap.size, total, same_state?(rebuilt, full))
end
