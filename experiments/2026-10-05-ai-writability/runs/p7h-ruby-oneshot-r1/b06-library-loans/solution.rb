#!/usr/bin/env ruby

class Library
  def initialize
    @current_day = 0
    @members = {}
    @books = {}
    @holds = {}
    @line = {}
  end

  def run
    line_num = 0
    STDIN.each_line do |line|
      line_num += 1
      line.strip!
      next if line.empty?

      parts = line.split

      if !parts[0] || !/^\d+$/.match?(parts[0])
        puts "line #{line_num}: error: bad day"
        next
      end

      day = parts[0].to_i
      if day < @current_day
        puts "line #{line_num}: error: day goes backwards"
        next
      end
      @current_day = day if day >= @current_day

      command = parts[1]
      case command
      when 'CHECKOUT'
        handle_checkout(line_num, parts)
      when 'RETURN'
        handle_return(line_num, parts)
      when 'RESERVE'
        handle_reserve(line_num, parts)
      when 'PAY'
        handle_pay(line_num, parts)
      else
        puts "line #{line_num}: error: unknown command"
      end
    end

    print_report
  end

  def handle_checkout(line_num, parts)
    if parts.size != 4
      puts "line #{line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    book = parts[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      return
    end
    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      return
    end

    @members[member] ||= { loans: [], owes: 0.0 }

    if @books[book] && @books[book][:on_loan]
      puts "line #{line_num}: refused: #{book} is on loan"
      return
    end

    if @holds[book] && @holds[book] != member
      puts "line #{line_num}: refused: #{book} is held for #{@holds[book]}"
      return
    end

    if @members[member][:loans].any? { |b, due| due < @current_day }
      puts "line #{line_num}: refused: #{member} has overdue books"
      return
    end

    if @members[member][:loans].size >= 3
      puts "line #{line_num}: refused: #{member} has 3 loans"
      return
    end

    if @members[member][:owes] >= 10.0
      puts "line #{line_num}: refused: #{member} owes #{format_money(@members[member][:owes])}"
      return
    end

    due_day = @current_day + 14
    @members[member][:loans] << [book, due_day]
    @books[book] = { on_loan: true, borrower: member, due: due_day }
    @holds.delete(book)
    @line[book] = [] if @line[book].nil?

    puts "#{member} borrowed #{book}, due day #{due_day}"
  end

  def handle_return(line_num, parts)
    if parts.size != 3
      puts "line #{line_num}: error: wrong field count"
      return
    end

    book = parts[2]

    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      return
    end

    if !@books[book] || !@books[book][:on_loan]
      puts "line #{line_num}: refused: #{book} is not on loan"
      return
    end

    borrower = @books[book][:borrower]
    due_day = @books[book][:due]
    days_late = @current_day - due_day

    fine = 0.0
    if days_late > 0
      fine = [days_late * 0.25, 5.0].min
      @members[borrower][:owes] += fine
      puts "#{borrower} returned #{book}, #{days_late} days late, fine #{format_money(fine)}"
    else
      puts "#{borrower} returned #{book}"
    end

    @books[book][:on_loan] = false
    @members[borrower][:loans].delete_if { |b, _| b == book }

    if @line[book] && !@line[book].empty?
      next_member = @line[book].shift
      @holds[book] = next_member
      puts "#{book} held for #{next_member}"
    end
  end

  def handle_reserve(line_num, parts)
    if parts.size != 4
      puts "line #{line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    book = parts[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      return
    end
    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      return
    end

    @members[member] ||= { loans: [], owes: 0.0 }

    if @members[member][:loans].any? { |b, _| b == book }
      puts "line #{line_num}: refused: #{member} already has #{book}"
      return
    end

    if @holds[book] == member || (@line[book] && @line[book].include?(member))
      puts "line #{line_num}: refused: #{member} already reserved #{book}"
      return
    end

    if !@books[book] || !@books[book][:on_loan]
      puts "line #{line_num}: refused: #{book} is available"
      return
    end

    @line[book] ||= []
    @line[book] << member
    position = @line[book].index(member) + 1
    puts "reserved #{book} for #{member} (position #{position})"
  end

  def handle_pay(line_num, parts)
    if parts.size != 4
      puts "line #{line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    amount_str = parts[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      return
    end

    if !valid_amount?(amount_str)
      puts "line #{line_num}: error: bad amount"
      return
    end

    amount = amount_str.to_f
    @members[member] ||= { loans: [], owes: 0.0 }

    if amount > @members[member][:owes]
      puts "line #{line_num}: refused: #{member} owes only #{format_money(@members[member][:owes])}"
      return
    end

    @members[member][:owes] -= amount
    puts "#{member} paid #{format_money(amount)}, owes #{format_money(@members[member][:owes])}"
  end

  def valid_member?(m)
    /^[a-z]{1,12}$/.match?(m)
  end

  def valid_book?(b)
    /^[A-Z][A-Z0-9]{0,7}$/.match?(b)
  end

  def valid_amount?(a)
    /^(0|[1-9]\d*)(\.\d{1,2})?$/.match?(a) && a.to_f > 0
  end

  def format_money(amount)
    format("%.2f", amount)
  end

  def print_report
    sorted_members = @members.keys.sort

    puts "member       loans     owes"
    sorted_members.each do |member|
      loans_count = @members[member][:loans].size
      owes = @members[member][:owes]
      puts format("%-12s %5d %8s", member, loans_count, format_money(owes))
    end

    overdue = []
    @members.each do |member, data|
      data[:loans].each do |book, due_day|
        if due_day < @current_day
          overdue << [due_day, book, member]
        end
      end
    end

    overdue.sort!
    puts "overdue on day #{@current_day}:"
    if overdue.empty?
      puts "  none"
    else
      overdue.each do |due_day, book, member|
        days_late = @current_day - due_day
        puts "  #{book} #{member} due #{due_day} (#{days_late} days)"
      end
    end
  end
end

lib = Library.new
lib.run
