class Title
  attr_reader :isbn, :name, :holds
  attr_accessor :copies

  def initialize(isbn, name, copies)
    @isbn = isbn
    @name = name
    @copies = copies
    @holds = []
  end
end

class Member
  attr_reader :id, :name, :tier, :loans
  attr_accessor :fines

  def initialize(id, name, tier)
    @id = id
    @name = name
    @tier = tier
    @fines = 0
    @loans = []
  end
end

class Loan
  attr_reader :isbn, :member, :out_day
  attr_accessor :due_day, :renewals

  def initialize(isbn, member, out_day, due_day)
    @isbn = isbn
    @member = member
    @out_day = out_day
    @due_day = due_day
    @renewals = 0
  end
end

class LoanRefused < StandardError
  attr_reader :member, :reason

  def initialize(message, member, reason)
    super(message)
    @member = member
    @reason = reason
  end
end

def loan_limit(tier) = tier == :staff ? 5 : (tier == :adult ? 3 : 2)
def loan_days(tier) = tier == :child ? 21 : 14
def daily_fine(tier) = tier == :child ? 5 : 25

class Library
  attr_reader :titles, :members, :log, :collected

  def initialize
    @titles = {}
    @members = {}
    @log = []
    @collected = 0
  end

  def title(isbn) = @titles[isbn]
  def member(id) = @members[id]

  def note(day, msg) = @log << format("d%02d %s", day, msg)

  def checkout(day, id, isbn)
    m = member(id)
    t = title(isbn)
    raise LoanRefused.new("unknown title #{isbn}", id, :unknown) if !t    
    raise LoanRefused.new("#{m.name} owes fines", id, :fines) if m.fines >= 500
    raise LoanRefused.new("#{m.name} at limit", id, :limit) if m.loans.size >= loan_limit(m.tier)
    holds = t.holds
    first_hold = holds.first
    if t.copies == 0 || (first_hold && first_hold != id)
      holds << id unless holds.include?(id)
      note(day, "#{m.name} placed hold on #{t.name} (position #{holds.index(id) + 1})")
      return nil
    end
    holds.shift if first_hold == id
    t.copies -= 1
    loan = Loan.new(isbn, id, day, day + loan_days(m.tier))
    m.loans << loan
    note(day, "#{m.name} borrowed #{t.name}, due d#{loan.due_day}")
    loan
  end

  def renew(day, id, isbn)
    m = member(id)
    loan = m.loans.find { |ln| ln.isbn == isbn }
    return note(day, "#{m.name} has no loan of #{isbn}") if !loan    
    t = title(isbn)
    if !t.holds.empty? || loan.renewals >= 2
      note(day, "renewal refused for #{m.name}: #{t.name}")
    else
      loan.renewals += 1
      loan.due_day += 7
      note(day, "#{m.name} renewed #{t.name} to d#{loan.due_day}")
    end
  end

  def checkin(day, id, isbn)
    m = member(id)
    idx = m.loans.find_index { |ln| ln.isbn == isbn }
    return note(day, "nothing to return for #{m.name}") if !idx    
    loan = m.loans.delete_at(idx)
    late = day - loan.due_day
    if late > 0
      fine = late * daily_fine(m.tier)
      m.fines += fine
      note(day, "#{m.name} returned #{isbn} #{late} days late, fine #{fine}")
    else
      note(day, "#{m.name} returned #{isbn}")
    end
    t = title(isbn)
    t.copies += 1
    nxt = t.holds.first
    note(day, "  #{t.name} is waiting for #{member(nxt).name}") if nxt
  end

  def pay(day, id, amount)
    m = member(id)
    paid = amount.clamp(0, m.fines)
    m.fines -= paid
    @collected += paid
    note(day, "#{m.name} paid #{paid}")
  end
end

lib = Library.new
[["111", "Dune", 2], ["222", "Emma", 1], ["333", "Ulysses", 1], ["444", "Matilda", 3]].each do |isbn, name, n|
  lib.titles[isbn] = Title.new(isbn, name, n)
end
[["m1", "Ana", :adult], ["m2", "Bo", :child], ["m3", "Cy", :staff], ["m4", "Di", :adult]].each do |id, name, tier|
  lib.members[id] = Member.new(id, name, tier)
end

script = [
  [1, :out, "m1", "111"], [1, :out, "m2", "444"], [2, :out, "m4", "222"], [2, :out, "m1", "222"],
  [3, :out, "m3", "111"], [3, :out, "m2", "111"], [4, :out, "m2", "333"], [5, :out, "m2", "444"],
  [10, :renew, "m4", "222"], [14, :renew, "m3", "111"], [16, :in, "m4", "222"], [17, :out, "m1", "222"],
  [20, :in, "m1", "111"], [21, :out, "m2", "111"], [22, :out, "m1", "999"], [30, :in, "m3", "111"],
  [33, :in, "m1", "222"], [40, :in, "m2", "444"], [41, :out, "m1", "333"], [45, :pay, "m1", 200],
  [50, :in, "m2", "111"], [50, :in, "m2", "333"], [51, :out, "m1", "333"], [52, :in, "m4", "444"]
]

refusals = Hash.new(0)
script.each do |day, action, id, arg|
  case action
  when :out then lib.checkout(day, id, arg)
  when :in then lib.checkin(day, id, arg)
  when :renew then lib.renew(day, id, arg)
  when :pay then lib.pay(day, id, arg)
  end
rescue LoanRefused => e
  refusals[e.reason] += 1
  lib.note(day, "refused: #{e.message}")
end

lib.log.each { |line| puts line }
puts "--- members"
lib.members.each do |id, m|
  out = m.loans.map { |ln| "#{ln.isbn}(due d#{ln.due_day})" }
  puts format("%-3s %-4s %-6s fines %4d  loans: %s", id, m.name, m.tier, m.fines, out.empty? ? "-" : out.join(" "))
end
puts "--- titles"
lib.titles.each_value do |t|
  puts "#{t.name.ljust(8)} on shelf #{t.copies} holds #{t.holds.size}"
end
puts "refusals: #{refusals.map { |r, n| "#{r}=#{n}" }.join(" ")}"
puts "fines collected: #{lib.collected}, outstanding: #{lib.members.values.sum(&:fines)}"
