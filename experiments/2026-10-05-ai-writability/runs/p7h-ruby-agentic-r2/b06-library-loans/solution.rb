#!/usr/bin/env ruby

class LibrarySystem
  def initialize
    @current_day = 0
    @books = {}  # book_id => {member:, due_day:}
    @holds = {}  # book_id => [member1, member2, ...]
    @members = {}  # member_id => {owes:, loans: [], active:}
  end

  def run
    line_num = 0
    STDIN.each_line do |line|
      line_num += 1
      line = line.strip
      next if line.empty?

      process_line(line, line_num)
    end

    print_report
  end

  private

  def process_line(line, line_num)
    parts = line.split
    return error(line_num, "bad day") if parts.empty? || !parts[0].match?(/^\d+$/)

    day = parts[0].to_i
    return error(line_num, "day goes backwards") if day < @current_day

    @current_day = day

    return error(line_num, "unknown command") if parts.size < 2

    command = parts[1]

    case command
    when "CHECKOUT"
      return error(line_num, "wrong field count") if parts.size != 4
      process_checkout(parts[2], parts[3], line_num)
    when "RETURN"
      return error(line_num, "wrong field count") if parts.size != 3
      process_return(parts[2], line_num)
    when "RESERVE"
      return error(line_num, "wrong field count") if parts.size != 4
      process_reserve(parts[2], parts[3], line_num)
    when "PAY"
      return error(line_num, "wrong field count") if parts.size != 4
      process_pay(parts[2], parts[3], line_num)
    else
      error(line_num, "unknown command")
    end
  end

  def validate_member(member, line_num)
    return true if member.match?(/^[a-z]{1,12}$/)
    error(line_num, "bad member")
    false
  end

  def validate_book(book, line_num)
    return true if book.match?(/^[A-Z][A-Z0-9]{0,7}$/)
    error(line_num, "bad book")
    false
  end

  def validate_amount(amount, line_num)
    return true if amount.match?(/^\d+(\.\d{1,2})?$/) && amount.to_f > 0
    error(line_num, "bad amount")
    false
  end

  def process_checkout(member, book, line_num)
    return unless validate_member(member, line_num) && validate_book(book, line_num)

    ensure_member(member)

    if @books[book]
      return refused(line_num, "#{book} is on loan")
    end

    if @holds[book] && @holds[book][0] != member
      return refused(line_num, "#{book} is held for #{@holds[book][0]}")
    end

    if has_overdue_books(member)
      return refused(line_num, "#{member} has overdue books")
    end

    if @members[member][:loans].size >= 3
      return refused(line_num, "#{member} has 3 loans")
    end

    if @members[member][:owes] >= 10.00
      return refused(line_num, "#{member} owes #{format('%.2f', @members[member][:owes])}")
    end

    due_day = @current_day + 14
    @books[book] = {member:, due_day:}
    @members[member][:loans] << book
    @holds[book] = @holds[book].drop(1) if @holds[book]
    activate_member(member)

    puts "#{member} borrowed #{book}, due day #{due_day}"
  end

  def process_return(book, line_num)
    return unless validate_book(book, line_num)

    unless @books[book]
      return refused(line_num, "#{book} is not on loan")
    end

    member = @books[book][:member]
    due_day = @books[book][:due_day]
    days_late = @current_day - due_day

    @books.delete(book)
    @members[member][:loans].delete(book)

    if days_late > 0
      fine = [days_late * 0.25, 5.00].min
      @members[member][:owes] += fine
      puts "#{member} returned #{book}, #{days_late} days late, fine #{format('%.2f', fine)}"
    else
      puts "#{member} returned #{book}"
    end

    if @holds[book] && @holds[book].size > 0
      first_holder = @holds[book][0]
      puts "#{book} held for #{first_holder}"
    end
  end

  def process_reserve(member, book, line_num)
    return unless validate_member(member, line_num) && validate_book(book, line_num)

    ensure_member(member)

    if @books[book] && @books[book][:member] == member
      return refused(line_num, "#{member} already has #{book}")
    end

    if @holds[book] && @holds[book].include?(member)
      return refused(line_num, "#{member} already reserved #{book}")
    end

    if !@books[book] && (!@holds[book] || @holds[book].empty?)
      return refused(line_num, "#{book} is available")
    end

    @holds[book] ||= []
    @holds[book] << member
    position = @holds[book].index(member) + 1
    activate_member(member)

    puts "reserved #{book} for #{member} (position #{position})"
  end

  def process_pay(member, amount, line_num)
    return unless validate_member(member, line_num) && validate_amount(amount, line_num)

    ensure_member(member)

    amount_f = amount.to_f
    if amount_f > @members[member][:owes]
      return refused(line_num, "#{member} owes only #{format('%.2f', @members[member][:owes])}")
    end

    @members[member][:owes] -= amount_f
    new_owed = @members[member][:owes]
    puts "#{member} paid #{amount}, owes #{format('%.2f', new_owed)}"
  end

  def ensure_member(member)
    @members[member] ||= {owes: 0.0, loans: [], active: false}
  end

  def activate_member(member)
    ensure_member(member)
    @members[member][:active] = true
  end

  def has_overdue_books(member)
    @members[member][:loans].any? { |book| @books[book][:due_day] < @current_day }
  end

  def error(line_num, message)
    puts "line #{line_num}: error: #{message}"
  end

  def refused(line_num, message)
    puts "line #{line_num}: refused: #{message}"
  end

  def print_report
    active_members = @members.select { |_, info| info[:active] }
    return if active_members.empty?

    puts format("%-12s %5s %8s", "member", "loans", "owes")
    active_members.keys.sort.each do |member|
      loans_count = @members[member][:loans].size
      owes = @members[member][:owes]
      puts format("%-12s %5d %8s", member, loans_count, format('%.2f', owes))
    end

    puts "overdue on day #{@current_day}:"
    overdue = []
    @books.each do |book, info|
      if info[:due_day] < @current_day
        overdue << [info[:due_day], book, info[:member]]
      end
    end

    if overdue.empty?
      puts "  none"
    else
      overdue.sort.each do |due_day, book, member|
        days = @current_day - due_day
        puts "  #{book} #{member} due #{due_day} (#{days} days)"
      end
    end
  end
end

system = LibrarySystem.new
system.run
