#!/usr/bin/env ruby

current_day = 0
books_on_loan = {}  # book -> {member, due_day}
holds = {}          # book -> [member1, member2, ...]
member_loans = {}   # member -> [books]
member_debts = {}   # member -> amount
all_members = Set.new

def valid_day?(s)
  s =~ /^\d+$/ && !s.start_with?('0') || s == '0'
end

def valid_member?(s)
  s =~ /^[a-z]{1,12}$/
end

def valid_book?(s)
  s =~ /^[A-Z][A-Z0-9]{0,7}$/
end

def valid_amount?(s)
  s =~ /^\d+(\.\d{1,2})?$/ && s.to_f > 0
end

$stdin.each_line.with_index do |line, idx|
  line_num = idx + 1
  line = line.chomp
  next if line.empty?

  fields = line.split

  if fields.empty?
    next
  end

  # Validate day
  if !valid_day?(fields[0])
    puts "line #{line_num}: error: bad day"
    next
  end

  day = fields[0].to_i
  if day < current_day
    puts "line #{line_num}: error: day goes backwards"
    next
  end
  current_day = day

  # Validate command
  if fields.size < 2
    puts "line #{line_num}: error: wrong field count"
    next
  end

  cmd = fields[1]
  case cmd
  when "CHECKOUT"
    # CHECKOUT member book
    if fields.size != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    member = fields[2]
    book = fields[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      next
    end
    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      next
    end

    # Check refusal conditions in order
    if books_on_loan[book]
      puts "line #{line_num}: refused: #{book} is on loan"
      next
    end

    if holds[book] && holds[book][0] != member
      puts "line #{line_num}: refused: #{book} is held for #{holds[book][0]}"
      next
    end

    # Check for overdue books
    has_overdue = false
    (member_loans[member] || []).each do |b|
      if books_on_loan[b] && books_on_loan[b][:due_day] < current_day
        has_overdue = true
        break
      end
    end
    if has_overdue
      puts "line #{line_num}: refused: #{member} has overdue books"
      next
    end

    if (member_loans[member] || []).size >= 3
      puts "line #{line_num}: refused: #{member} has 3 loans"
      next
    end

    if (member_debts[member] || 0) >= 10.00
      debt = member_debts[member] || 0
      puts "line #{line_num}: refused: #{member} owes #{format('%.2f', debt)}"
      next
    end

    # Perform checkout
    all_members << member
    member_loans[member] ||= []
    member_loans[member] << book
    due_day = current_day + 14
    books_on_loan[book] = {member: member, due_day: due_day}

    # Remove hold for this member
    if holds[book] && holds[book][0] == member
      holds[book].shift
      holds.delete(book) if holds[book].empty?
    end

    puts "#{member} borrowed #{book}, due day #{due_day}"

  when "RETURN"
    # RETURN book
    if fields.size != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    book = fields[2]
    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      next
    end

    if !books_on_loan[book]
      puts "line #{line_num}: refused: #{book} is not on loan"
      next
    end

    member = books_on_loan[book][:member]
    due_day = books_on_loan[book][:due_day]
    days_late = current_day - due_day

    member_loans[member].delete(book)

    if days_late > 0
      fine = (days_late * 0.25).min(5.00)
      member_debts[member] = (member_debts[member] || 0) + fine
      puts "#{member} returned #{book}, #{days_late} days late, fine #{format('%.2f', fine)}"
    else
      puts "#{member} returned #{book}"
    end

    books_on_loan.delete(book)

    # Check holds
    if holds[book] && !holds[book].empty?
      next_member = holds[book][0]
      puts "#{book} held for #{next_member}"
    end

  when "RESERVE"
    # RESERVE member book
    if fields.size != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    member = fields[2]
    book = fields[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      next
    end
    if !valid_book?(book)
      puts "line #{line_num}: error: bad book"
      next
    end

    # Check refusal conditions
    if member_loans[member] && member_loans[member].include?(book)
      puts "line #{line_num}: refused: #{member} already has #{book}"
      next
    end

    if holds[book] && holds[book].include?(member)
      puts "line #{line_num}: refused: #{member} already reserved #{book}"
      next
    end

    if !books_on_loan[book] && !holds[book]
      puts "line #{line_num}: refused: #{book} is available"
      next
    end

    # Add to hold
    all_members << member
    holds[book] ||= []
    holds[book] << member
    position = holds[book].size
    puts "reserved #{book} for #{member} (position #{position})"

  when "PAY"
    # PAY member amount
    if fields.size != 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    member = fields[2]
    amount_str = fields[3]

    if !valid_member?(member)
      puts "line #{line_num}: error: bad member"
      next
    end
    if !valid_amount?(amount_str)
      puts "line #{line_num}: error: bad amount"
      next
    end

    amount = amount_str.to_f
    owed = member_debts[member] || 0

    if amount > owed
      puts "line #{line_num}: refused: #{member} owes only #{format('%.2f', owed)}"
      next
    end

    member_debts[member] = owed - amount
    puts "#{member} paid #{format('%.2f', amount)}, owes #{format('%.2f', member_debts[member])}"

  else
    puts "line #{line_num}: error: unknown command"
  end
end

# Final report
puts format("%-12s %5s %8s", "member", "loans", "owes")
all_members.sort.each do |member|
  loans_count = (member_loans[member] || []).size
  debt = member_debts[member] || 0
  puts format("%-12s %5d %8s", member, loans_count, format('%.2f', debt))
end

puts "overdue on day #{current_day}:"
overdue = []
member_loans.each do |member, books|
  books.each do |book|
    if books_on_loan[book] && books_on_loan[book][:due_day] < current_day
      due_day = books_on_loan[book][:due_day]
      days_late = current_day - due_day
      overdue << [due_day, book, member, days_late]
    end
  end
end

if overdue.empty?
  puts "  none"
else
  overdue.sort.each do |due_day, book, member, days_late|
    puts "  #{book} #{member} due #{due_day} (#{days_late} days)"
  end
end
