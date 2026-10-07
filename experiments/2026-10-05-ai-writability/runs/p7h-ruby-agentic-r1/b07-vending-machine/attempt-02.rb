class VendingMachine
  VALID_COINS = [0.05, 0.10, 0.25, 0.50, 1.00, 2.00].freeze

  def initialize
    @slots = {}  # code -> {name:, price:, count:}
    @tubes = {0.05 => 0, 0.10 => 0, 0.25 => 0, 0.50 => 0, 1.00 => 0, 2.00 => 0}
    @credit = 0.0
    @inserted_coins = []  # list of coins inserted
    @sales = {}  # name -> {count:, revenue:}
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
    command = parts[0]

    case command
    when 'SLOT'
      process_slot(parts)
    when 'TUBE'
      process_tube(parts)
    when 'COIN'
      process_coin(parts)
    when 'SELECT'
      process_select(parts)
    when 'CANCEL'
      process_cancel(parts)
    else
      puts "line #{@line_num}: error: unknown command"
    end
  end

  def validate_slot(code)
    code =~ /^[A-Z]\d$/
  end

  def validate_name(name)
    name =~ /^[a-z]{1,12}$/
  end

  def validate_money(money)
    money =~ /^\d+\.\d{2}$/ && money.to_f > 0
  end

  def validate_coin(coin)
    VALID_COINS.include?(coin.to_f)
  end

  def validate_count(count)
    count.to_i >= 0 && count.to_i <= 999 && count =~ /^\d+$/
  end

  def process_slot(parts)
    unless parts.length == 5
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    code = parts[1]
    name = parts[2]
    price = parts[3]
    count = parts[4]

    unless validate_slot(code)
      puts "line #{@line_num}: error: bad slot"
      return
    end

    unless validate_name(name)
      puts "line #{@line_num}: error: bad name"
      return
    end

    unless validate_money(price)
      puts "line #{@line_num}: error: bad money"
      return
    end

    unless count =~ /^\d+$/ && count.to_i <= 99
      puts "line #{@line_num}: error: bad count"
      return
    end

    @slots[code] = {name: name, price: price.to_f, count: count.to_i}
  end

  def process_tube(parts)
    unless parts.length == 3
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    coin = parts[1]
    count = parts[2]

    unless validate_money(coin)
      puts "line #{@line_num}: error: bad coin"
      return
    end

    unless count =~ /^\d+$/ && count.to_i <= 999
      puts "line #{@line_num}: error: bad count"
      return
    end

    coin_f = coin.to_f
    unless validate_coin(coin)
      puts "line #{@line_num}: error: bad coin"
      return
    end

    @tubes[coin_f] += count.to_i
  end

  def process_coin(parts)
    unless parts.length == 2
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    coin = parts[1]

    unless validate_money(coin)
      puts "line #{@line_num}: error: bad money"
      return
    end

    coin_f = coin.to_f
    unless validate_coin(coin)
      puts "rejected #{coin}"
      return
    end

    if @credit + coin_f > 5.00
      puts "rejected #{coin} (credit limit)"
      return
    end

    @tubes[coin_f] += 1
    @credit += coin_f
    @inserted_coins.push(coin_f)
    puts "credit #{format('%.2f', @credit)}"
  end

  def process_select(parts)
    unless parts.length == 2
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    code = parts[1]

    unless @slots[code]
      puts "no slot #{code}"
      return
    end

    slot = @slots[code]

    if slot[:count] == 0
      puts "sold out #{code}"
      return
    end

    if @credit < slot[:price]
      need = slot[:price] - @credit
      puts "insert #{format('%.2f', need)} more"
      return
    end

    change_needed = @credit - slot[:price]

    # Try to make change
    change_coins = make_change(change_needed)
    if change_coins.nil?
      puts "exact change needed"
      return
    end

    # Remove coins from tubes
    change_coins.each do |coin|
      @tubes[coin] -= 1
    end

    # Remove item from slot
    slot[:count] -= 1

    # Record sale
    name = slot[:name]
    @sales[name] ||= {count: 0, revenue: 0.0}
    @sales[name][:count] += 1
    @sales[name][:revenue] += slot[:price]

    # Reset credit
    @credit = 0.0
    @inserted_coins = []

    # Print result
    if change_coins.empty?
      puts "vend #{name}"
    else
      change_str = change_coins.map { |c| format('%.2f', c) }.join(' ')
      puts "vend #{name}, change #{format('%.2f', change_needed)} [#{change_str}]"
    end
  end

  def make_change(amount)
    coins = []
    remaining = amount
    sorted_coins = [2.00, 1.00, 0.50, 0.25, 0.10, 0.05].sort.reverse

    sorted_coins.each do |coin|
      while remaining >= coin - 0.001 && @tubes[coin] - coins.count(coin) > 0
        coins.push(coin)
        remaining -= coin
        remaining = (remaining * 100).round / 100.0
      end
    end

    return nil unless (remaining.abs < 0.001)
    coins
  end

  def process_cancel(parts)
    unless parts.length == 1
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    if @credit == 0
      puts "nothing to return"
      return
    end

    # Return coins in the order they were inserted
    coins_str = @inserted_coins.map { |c| format('%.2f', c) }.join(' ')
    puts "returned #{format('%.2f', @credit)} [#{coins_str}]"

    # Remove coins from tubes
    @inserted_coins.each do |coin|
      @tubes[coin] -= 1
    end

    @credit = 0.0
    @inserted_coins = []
  end

  def output_report
    if @credit > 0
      puts "credit #{format('%.2f', @credit)} kept"
    end

    puts "sales:"
    if @sales.empty?
      puts "  none"
    else
      # Sort by revenue (highest first), then by name
      sorted = @sales.sort_by { |name, info| [-info[:revenue], name] }
      sorted.each do |name, info|
        puts "  %-12s %3d %8s" % [name, info[:count], format('%.2f', info[:revenue])]
      end
    end

    # Output tubes
    tube_str = @tubes.sort.map { |coin, count| "#{format('%.2f', coin)}x#{count}" }.join(' ')
    puts "tubes: #{tube_str}"
  end
end

machine = VendingMachine.new
machine.run(STDIN.read)
