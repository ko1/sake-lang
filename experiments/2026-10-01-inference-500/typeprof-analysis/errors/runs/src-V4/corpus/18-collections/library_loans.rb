# A small library: books with genre Sets, members, loans with due-day Ranges, reservations queues,
# overdue fines, and reports shared through a mixin module.

class LoanRefused < StandardError
  attr_reader :reason

  def initialize(message, reason)
    super(message)
    @reason = reason
  end
end

module Report
  def summary
    rows = lines
    "#{heading} (#{rows.size})\n" + rows.map { |r| "  " + r }.join("\n")
  end
end

class Book
  attr_reader :id, :title, :author, :genres, :copies

  def initialize(id, title, author, genres, copies)
    @id = id
    @title = title
    @author = author
    @genres = genres
    @copies = copies
  end
end

class Member
  include Report
  attr_reader :id, :name, :kind

  def initialize(id, name, kind)
    @id = id
    @name = name
    @kind = kind
  end

  def heading = "#{@name} (#{@kind})"
  def lines = ["id #{@id}"]
end

class Loan
  attr_reader :book_id, :member_id, :period
  attr_accessor :returned

  def initialize(book_id, member_id, period, returned)
    @book_id = book_id
    @member_id = member_id
    @period = period
    @returned = returned
  end
end

def fine(days) = format("$%.2f", (days * 0.25).clamp(0.0, 5.0))

class Library
  include Report
  attr_reader :books, :members, :loans, :queues, :today

  def initialize(today)
    @books = {}
    @members = {}
    @loans = []
    @queues = {}
    @today = today
  end

  def add_book(id, title, author, genres, copies)
    @books[id] = Book.new(id, title, author, genres.split(",").to_set, copies)
  end

  def add_member(id, name, kind) = @members[id] = Member.new(id, name, kind)

  def loan_days(member) = member.kind == :staff ? 28 : 14

  def active = @loans.select { |l| !l.returned     }

  def out_count(book_id) = active.count { |l| l.book_id == book_id }

  def available?(book_id) = out_count(book_id) < @books[book_id].copies

  def lend(book_id, member_id, day)
    book = @books[book_id]
    member = @members[member_id]
    raise LoanRefused.new("cannot lend", "no such book #{book_id}") unless book
    raise LoanRefused.new("cannot lend", "no such member #{member_id}") unless member
    mine = active.count { |l| l.member_id == member_id }
    raise LoanRefused.new("cannot lend", "#{member.name} has #{mine} books out") if mine >= 3
    queue = @queues.fetch(book_id, [])
    unless queue.empty? || queue[0] == member_id
      raise LoanRefused.new("cannot lend", "reserved for #{@members[queue[0]].name}")
    end
    raise LoanRefused.new("cannot lend", "no copy of #{book.title} left") unless available?(book_id)
    queue.shift if queue[0] == member_id
    loan = Loan.new(book_id, member_id, day...(day + loan_days(member)), nil)
    @loans << loan
    loan
  end

  def give_back(book_id, member_id, day)
    loan = active.find { |l| l.book_id == book_id && l.member_id == member_id }
    return nil unless loan
    loan.returned = day
    late = day - (loan.period.end - 1)
    late > 0 ? late : 0
  end

  def reserve(book_id, member_id)
    q = (@queues[book_id] ||= [])
    q << member_id unless q.include?(member_id)
    q.index(member_id) + 1
  end

  def overdue = active.select { |l| @today >= l.period.end }

  def heading = "Overdue on day #{@today}"

  def lines
    overdue.map do |l|
      days = @today - l.period.end + 1
      "#{@books[l.book_id].title} - #{@members[l.member_id].name}, #{days} days, fine #{fine(days)}"
    end
  end
end

lib = Library.new(40)
lib.add_book("b1", "Dune", "Herbert", "scifi,classic", 2)
lib.add_book("b2", "Emma", "Austen", "romance,classic", 1)
lib.add_book("b3", "Neuromancer", "Gibson", "scifi,cyberpunk", 1)
lib.add_book("b4", "The Hobbit", "Tolkien", "fantasy,classic", 3)
lib.add_book("b5", "Snow Crash", "Stephenson", "scifi,cyberpunk,satire", 1)
lib.add_member("m1", "Ann", :adult)
lib.add_member("m2", "Bo", :staff)
lib.add_member("m3", "Cy", :adult)
lib.add_member("m4", "Di", :child)

requests = [
  ["lend", "b1", "m1", 1], ["lend", "b3", "m1", 2], ["lend", "b3", "m2", 3], ["reserve", "b3", "m3", 3],
  ["reserve", "b3", "m2", 4], ["lend", "b2", "m4", 5], ["lend", "b4", "m1", 6], ["lend", "b5", "m1", 7],
  ["return", "b2", "m4", 18], ["return", "b2", "m4", 19], ["return", "b3", "m1", 20], ["lend", "b3", "m2", 21],
  ["lend", "b3", "m3", 22], ["lend", "b9", "m3", 22], ["lend", "b5", "m2", 23], ["lend", "b4", "m4", 25],
  ["return", "b1", "m1", 30], ["lend", "b1", "m3", 30]
]
puts "== Desk log =="
requests.each do |action, book, member, day|
  case action
  when "lend"
    loan = lib.lend(book, member, day)
    puts format("day %2d lend   %s -> %s, due day %d", day, book, member, loan.period.end - 1)
  when "return"
    late = lib.give_back(book, member, day)
    if !late    
      puts format("day %2d return %s by %s: no such loan", day, book, member)
    else
      puts format("day %2d return %s by %s%s", day, book, member, late > 0 ? ", #{late} days late, fine #{fine(late)}" : "")
    end
  when "reserve"
    pos = lib.reserve(book, member)
    puts format("day %2d reserve %s for %s, position %d", day, book, member, pos)
  end
rescue LoanRefused => e
  puts format("day %2d refused %s for %s: %s", day, book, member, e.reason)
end

puts
puts lib.summary
puts lib.members["m2"].summary

puts "== Holdings =="
books = lib.books.values
books.each do |b|
  q = lib.queues.fetch(b.id, [])
  puts format("  %-12s %d/%d out%s", b.title, lib.out_count(b.id), b.copies, q.empty? ? "" : ", queue #{q.join(",")}")
end

genres = books.reduce(Set[]) { |acc, b| acc | b.genres }
puts "genres: #{genres.sort.join(" ")}"
loans = lib.loans
by_member = loans.group_by(&:member_id)
by_member.each do |mid, ls|
  read = ls.reduce(Set[]) { |acc, l| acc | lib.books[l.book_id].genres }
  puts "  #{lib.members[mid].name} borrowed #{ls.size}, genres: #{read.sort.join(",")}"
end
scifi_fans = by_member.keys.select do |mid|
  by_member[mid].all? { |l| lib.books[l.book_id].genres.include?("scifi") }
end
puts "only scifi: #{scifi_fans.join(", ")}"
never = books.reject { |b| loans.any? { |l| l.book_id == b.id } }
puts "never borrowed: #{never.empty? ? "none" : never.map(&:title).join(", ")}"
durations = loans.filter_map { |l| l.returned ? l.returned - l.period.begin : nil }
puts "returned loans: #{durations.size}, average #{format("%.1f", durations.sum / durations.size.to_f)} days"
