class Book
  attr_reader :isbn, :title, :author, :copies
  attr_accessor :on_loan

  def initialize(isbn, title, author, copies, on_loan)
    @isbn = isbn
    @title = title
    @author = author
    @copies = copies
    @on_loan = on_loan
  end

  def available = copies - on_loan
end

class Member
  attr_reader :id, :name, :limit
  attr_accessor :fines

  def initialize(id, name, limit, fines)
    @id = id
    @name = name
    @limit = limit
    @fines = fines
  end
end

class Loan
  attr_reader :isbn, :member_id, :out_day, :due_day
  attr_accessor :back_day

  def initialize(isbn, member_id, out_day, due_day, back_day)
    @isbn = isbn
    @member_id = member_id
    @out_day = out_day
    @due_day = due_day
    @back_day = back_day
  end
end

class LoanError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

LOAN_DAYS = 14
FINE_PER_DAY = 25
FINE_CAP = 500

class Library
  attr_reader :books, :members, :loans

  def initialize
    @books = {}
    @members = {}
    @loans = []
  end

  def add_book(isbn, title, author, copies)
    @books[isbn] = Book.new(isbn, title, author, copies, 0)
  end

  def add_member(id, name, limit)
    @members[id] = Member.new(id, name, limit, 0)
  end

  def open_loans_of(member_id)
    @loans.select { |l| l.member_id == member_id && l.back_day.nil? }
  end

  def checkout(member_id, isbn, day)
    member = @members[member_id]
    raise LoanError.new("no such member #{member_id}", :member) if member.nil?
    book = @books[isbn]
    raise LoanError.new("no such book #{isbn}", :book) if book.nil?
    if member.fines > 0
      raise LoanError.new("#{member.name} owes #{member.fines} cents", :fines)
    end
    if open_loans_of(member_id).size >= member.limit
      raise LoanError.new("#{member.name} reached the limit", :limit)
    end
    if book.available <= 0
      raise LoanError.new("'#{book.title}' is not available", :copies)
    end
    book.on_loan += 1
    loan = Loan.new(isbn, member_id, day, day + LOAN_DAYS, nil)
    @loans << loan
    loan
  end

  def checkin(member_id, isbn, day)
    loan = @loans.find do |l|
      l.member_id == member_id && l.isbn == isbn && l.back_day.nil?
    end
    raise LoanError.new("#{member_id} has no open loan of #{isbn}", :loan) unless loan
    loan.back_day = day
    book = @books.fetch(isbn)
    book.on_loan -= 1
    late = day - loan.due_day
    fine = 0
    if late > 0
      fine = (late * FINE_PER_DAY).clamp(0, FINE_CAP)
      member = @members.fetch(member_id)
      member.fines += fine
    end
    fine
  end

  def pay(member_id, amount)
    member = @members.fetch(member_id)
    paid = amount.clamp(0, member.fines)
    member.fines -= paid
    paid
  end

  def overdue(today)
    @loans.select { |l| l.back_day.nil? && l.due_day < today }
  end
end

def money(cents) = format("$%d.%02d", cents / 100, cents % 100)

def try(label)
  result = yield
  puts "ok   #{label}: #{result}"
rescue LoanError => e
  puts "FAIL #{label}: #{e.message} [#{e.code}]"
end

lib = Library.new
lib.add_book("978-0", "The Pragmatic Programmer", "Hunt", 2)
lib.add_book("978-1", "Refactoring", "Fowler", 1)
lib.add_book("978-2", "Domain-Driven Design", "Evans", 1)
lib.add_book("978-3", "Clean Architecture", "Martin", 3)
lib.add_member(1, "Ana", 2)
lib.add_member(2, "Ben", 3)
lib.add_member(3, "Cho", 1)

events = [
  [1, :out, 1, "978-0"], [2, :out, 1, "978-1"], [2, :out, 2, "978-1"],
  [3, :out, 1, "978-3"], [3, :out, 2, "978-0"], [4, :out, 3, "978-0"],
  [5, :out, 3, "978-2"], [6, :out, 2, "978-3"], [9, :out, 4, "978-2"], [10, :in, 2, "978-1"],
  [12, :out, 2, "978-1"], [20, :in, 1, "978-0"], [21, :in, 3, "978-2"],
  [22, :out, 3, "978-3"], [23, :pay, 3, "300"], [24, :in, 1, "978-1"],
  [30, :in, 2, "978-0"], [31, :pay, 3, "1000"], [32, :out, 3, "978-3"],
  [40, :in, 1, "978-3"]
]

events.each do |day, kind, who, arg|
  label = "day #{day} #{kind} m#{who} #{arg}"
  case kind
  when :out
    try(label) { "due day #{lib.checkout(who, arg, day).due_day}" }
  when :in
    try(label) { "fine #{money(lib.checkin(who, arg, day))}" }
  when :pay
    try(label) { "paid #{money(lib.pay(who, arg.to_i))}" }
  end
end

puts
puts "Overdue on day 40:"
lib.overdue(40).each do |l|
  book = lib.books.fetch(l.isbn)
  member = lib.members.fetch(l.member_id)
  days = 40 - l.due_day
  puts format("  %-28s %-4s %3d days late", book.title, member.name, days)
end

puts
puts "Shelf:"
lib.books.each_value do |b|
  puts format("  %-28s %-7s %d/%d available", b.title, b.author, b.available, b.copies)
end

puts
puts "Members:"
lib.members.each_value do |m|
  n = lib.open_loans_of(m.id).size
  puts format("  %-4s loans=%d fines=%s", m.name, n, money(m.fines))
end

counts = lib.loans.map(&:isbn).tally
top_n = counts.values.max
tops = counts.select { |_isbn, n| n == top_n }.keys
titles = tops.map { |isbn| lib.books.fetch(isbn).title }
puts "Most borrowed (#{top_n} loans): #{titles.join(", ")}"
