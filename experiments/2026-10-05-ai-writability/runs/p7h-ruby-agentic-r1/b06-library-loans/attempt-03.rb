class LibrarySim
  def initialize
    @current_day = 0
    @book_loans = {}  # book -> {member:, due_day:}
    @member_holds = {}  # book -> [members waiting]
    @members = {}  # member -> {loans: Set, owes: Float}
    @member_history = Set.new
    @line_num = 0
  end

  def run(input)
    input.each_line do |line|
      @line_num += 1
      process_line(line)
    end
    output_report
  end

  private

  def process_line(line)
    line = line.strip
    return if line.empty?

    parts = line.split

    # Check bad day
    unless parts[0] =~ /^\d+$/
      puts "line #{@line_num}: error: bad day"
      return
    end

    day = parts[0].to_i

    # Check day goes backwards
    if day < @current_day
      puts "line #{@line_num}: error: day goes backwards"
      return
    end

    @current_day = day

    # Check unknown command
    command = parts[1]
    unless %w[CHECKOUT RETURN RESERVE PAY].include?(command)
      puts "line #{@line_num}: error: unknown command"
      return
    end

    # Parse and validate based on command
    case command
    when 'CHECKOUT'
      process_checkout(parts)
    when 'RETURN'
      process_return(parts)
    when 'RESERVE'
      process_reserve(parts)
    when 'PAY'
      process_pay(parts)
    end
  end

  def validate_member(member)
    member =~ /^[a-z]{1,12}$/
  end

  def validate_book(book)
    book =~ /^[A-Z][A-Z0-9]{0,7}$/
  end

  def validate_amount(amount)
    amount =~ /^\d+(\.\d{1,2})?$/ && amount.to_f > 0
  end

  def process_checkout(parts)
    unless parts.length == 4
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    book = parts[3]

    unless validate_member(member)
      puts "line #{@line_num}: error: bad member"
      return
    end

    unless validate_book(book)
      puts "line #{@line_num}: error: bad book"
      return
    end

    # Check rules in order
    if @book_loans[book]
      puts "line #{@line_num}: refused: #{book} is on loan"
      return
    end

    if @member_holds[book] && !@member_holds[book].empty? && @member_holds[book][0] != member
      puts "line #{@line_num}: refused: #{book} is held for #{@member_holds[book][0]}"
      return
    end

    # Check overdue books
    member_loans = @members[member]&.[](:loans) || Set.new
    member_loans.each do |b|
      loan = @book_loans[b]
      if loan && loan[:due_day] < @current_day
        puts "line #{@line_num}: refused: #{member} has overdue books"
        return
      end
    end

    if member_loans.size >= 3
      puts "line #{@line_num}: refused: #{member} has 3 loans"
      return
    end

    owing = @members[member]&.[](:owes) || 0.0
    if owing >= 10.0
      puts "line #{@line_num}: refused: #{member} owes #{format('%.2f', owing)}"
      return
    end

    # Perform checkout
    @book_loans[book] = {member: member, due_day: @current_day + 14}
    @members[member] ||= {loans: Set.new, owes: 0.0}
    @members[member][:loans].add(book)
    @member_history.add(member)

    # Remove from hold queue if this member had a hold
    if @member_holds[book] && @member_holds[book][0] == member
      @member_holds[book].shift
    end

    puts "#{member} borrowed #{book}, due day #{@current_day + 14}"
  end

  def process_return(parts)
    unless parts.length == 3
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    book = parts[2]

    unless validate_book(book)
      puts "line #{@line_num}: error: bad book"
      return
    end

    loan = @book_loans[book]
    unless loan
      puts "line #{@line_num}: refused: #{book} is not on loan"
      return
    end

    member = loan[:member]
    due_day = loan[:due_day]
    days_late = @current_day - due_day

    # Calculate fine
    if days_late > 0
      fine = [days_late * 0.25, 5.0].min
      @members[member][:owes] += fine
      puts "#{member} returned #{book}, #{days_late} days late, fine #{format('%.2f', fine)}"
    else
      puts "#{member} returned #{book}"
    end

    # Remove loan
    @book_loans.delete(book)
    @members[member][:loans].delete(book)

    # Process holds queue
    if @member_holds[book] && !@member_holds[book].empty?
      next_member = @member_holds[book][0]
      puts "#{book} held for #{next_member}"
    end
  end

  def process_reserve(parts)
    unless parts.length == 4
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    book = parts[3]

    unless validate_member(member)
      puts "line #{@line_num}: error: bad member"
      return
    end

    unless validate_book(book)
      puts "line #{@line_num}: error: bad book"
      return
    end

    # Check rules
    if @book_loans[book]&.[](:member) == member
      puts "line #{@line_num}: refused: #{member} already has #{book}"
      return
    end

    if @member_holds[book] && @member_holds[book].include?(member)
      puts "line #{@line_num}: refused: #{member} already reserved #{book}"
      return
    end

    unless @book_loans[book] || (@member_holds[book] && !@member_holds[book].empty?)
      puts "line #{@line_num}: refused: #{book} is available"
      return
    end

    # Add to hold queue
    @member_holds[book] ||= []
    @member_holds[book].push(member)
    @members[member] ||= {loans: Set.new, owes: 0.0}
    @member_history.add(member)

    position = @member_holds[book].index(member) + 1
    puts "reserved #{book} for #{member} (position #{position})"
  end

  def process_pay(parts)
    unless parts.length == 4
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    member = parts[2]
    amount_str = parts[3]

    unless validate_member(member)
      puts "line #{@line_num}: error: bad member"
      return
    end

    unless validate_amount(amount_str)
      puts "line #{@line_num}: error: bad amount"
      return
    end

    amount = amount_str.to_f
    owing = @members[member]&.[](:owes) || 0.0

    if amount > owing
      puts "line #{@line_num}: refused: #{member} owes only #{format('%.2f', owing)}"
      return
    end

    @members[member][:owes] -= amount
    new_owing = @members[member][:owes]
    puts "#{member} paid #{format('%.2f', amount)}, owes #{format('%.2f', new_owing)}"
  end

  def output_report
    # Sort members by byte order
    sorted_members = @member_history.sort

    puts "%-12s %5s %8s" % ["member", "loans", "owes"]
    sorted_members.each do |member|
      info = @members[member]
      loans_count = info[:loans].size
      owes = info[:owes]
      puts "%-12s %5d %8s" % [member, loans_count, format('%.2f', owes)]
    end

    # Find overdue loans
    overdue = []
    @book_loans.each do |book, loan|
      if loan[:due_day] < @current_day
        overdue.push([loan[:due_day], book, loan[:member]])
      end
    end

    puts "overdue on day #{@current_day}:"
    if overdue.empty?
      puts "  none"
    else
      overdue.sort.each do |due_day, book, member|
        days_late = @current_day - due_day
        puts "  #{book} #{member} due #{due_day} (#{days_late} days)"
      end
    end
  end
end

sim = LibrarySim.new
sim.run(STDIN.read)
