#!/usr/bin/env ruby

class VendingMachine
  COINS = [0.05, 0.10, 0.25, 0.50, 1.00, 2.00].freeze

  def initialize
    @slots = {}  # code => {name:, price:, count:}
    @tubes = {0.05 => 0, 0.10 => 0, 0.25 => 0, 0.50 => 0, 1.00 => 0, 2.00 => 0}
    @credit = 0.0
    @inserted_coins = []  # coins in order inserted
    @sales = {}  # name => {count:, revenue:}
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
    return error(line_num, "unknown command") if parts.empty?

    command = parts[0]

    case command
    when "SLOT"
      return error(line_num, "wrong field count") if parts.size != 6
      process_slot(parts, line_num)
    when "TUBE"
      return error(line_num, "wrong field count") if parts.size != 3
      process_tube(parts, line_num)
    when "COIN"
      return error(line_num, "wrong field count") if parts.size != 2
      process_coin(parts[1], line_num)
    when "SELECT"
      return error(line_num, "wrong field count") if parts.size != 2
      process_select(parts[1], line_num)
    when "CANCEL"
      return error(line_num, "wrong field count") if parts.size != 1
      process_cancel
    else
      error(line_num, "unknown command")
    end
  end

  def validate_slot_code(code, line_num)
    return true if code.match?(/^[A-Z]\d$/)
    error(line_num, "bad slot")
    false
  end

  def validate_name(name, line_num)
    return true if name.match?(/^[a-z]{1,12}$/)
    error(line_num, "bad name")
    false
  end

  def validate_money(money, line_num)
    return true if money.match?(/^\d+\.\d{2}$/) && money.to_f > 0
    error(line_num, "bad money")
    false
  end

  def validate_coin(coin, line_num)
    return true if COINS.include?(coin.to_f)
    error(line_num, "bad coin")
    false
  end

  def validate_count(count, line_num, max_val = 99)
    val = count.to_i rescue -1
    return true if val.to_s == count && val >= 0 && val <= max_val
    error(line_num, "bad count")
    false
  end

  def process_slot(parts, line_num)
    code = parts[1]
    name = parts[2]
    money = parts[3]
    count = parts[4]

    return unless validate_slot_code(code, line_num)
    return unless validate_name(name, line_num)
    return unless validate_money(money, line_num)
    return unless validate_count(count, line_num, 99)

    @slots[code] = {name: name, price: money.to_f, count: count.to_i}
  end

  def process_tube(parts, line_num)
    coin = parts[1]
    count = parts[2]

    return unless validate_coin(coin, line_num)
    return unless validate_count(count, line_num, 999)

    coin_f = coin.to_f
    @tubes[coin_f] += count.to_i
  end

  def process_coin(coin, line_num)
    coin_f = coin.to_f

    unless COINS.include?(coin_f)
      puts "rejected #{coin}"
      return
    end

    if @credit + coin_f > 5.00
      puts "rejected #{coin} (credit limit)"
      return
    end

    @tubes[coin_f] += 1
    @credit += coin_f
    @inserted_coins << coin_f
    puts "credit #{format('%.2f', @credit)}"
  end

  def make_change(amount)
    change_coins = []
    remaining = amount
    coin_copy = @tubes.dup

    COINS.reverse_each do |coin|
      while remaining >= coin - 0.001 && coin_copy[coin] > 0
        change_coins << coin
        remaining -= coin
        coin_copy[coin] -= 1
      end
    end

    return nil if remaining > 0.001
    [change_coins, coin_copy]
  end

  def process_select(code, line_num)
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
      diff = slot[:price] - @credit
      puts "insert #{format('%.2f', diff)} more"
      return
    end

    change = @credit - slot[:price]

    if change == 0
      slot[:count] -= 1
      name = slot[:name]
      @sales[name] ||= {count: 0, revenue: 0.0}
      @sales[name][:count] += 1
      @sales[name][:revenue] += slot[:price]
      @credit = 0.0
      @inserted_coins = []
      puts "vend #{name}"
      return
    end

    # Try to make change
    result = make_change(change)

    if result.nil?
      puts "exact change needed"
      return
    end

    change_coins, new_tubes = result

    # Apply the change
    @tubes = new_tubes
    slot[:count] -= 1
    name = slot[:name]
    @sales[name] ||= {count: 0, revenue: 0.0}
    @sales[name][:count] += 1
    @sales[name][:revenue] += slot[:price]
    @credit = 0.0
    @inserted_coins = []

    change_str = change_coins.map { |c| format('%.2f', c) }.join(' ')
    puts "vend #{name}, change #{format('%.2f', change)} [#{change_str}]"
  end

  def process_cancel
    if @credit == 0
      puts "nothing to return"
      return
    end

    # Return coins in order inserted
    @inserted_coins.each { |coin| @tubes[coin] -= 1 }

    coins_str = @inserted_coins.map { |c| format('%.2f', c) }.join(' ')
    puts "returned #{format('%.2f', @credit)} [#{coins_str}]"
    @credit = 0.0
    @inserted_coins = []
  end

  def print_report
    if @credit != 0
      puts "credit #{format('%.2f', @credit)} kept"
    end

    puts "sales:"
    if @sales.empty?
      puts "  none"
    else
      sorted = @sales.sort_by { |name, data| [-data[:revenue], name] }
      sorted.each do |name, data|
        puts format("  %-12s %3d %8s", name, data[:count], format('%.2f', data[:revenue]))
      end
    end

    tubes_str = COINS.map { |coin| "#{format('%.2f', coin)}x#{@tubes[coin]}" }.join(' ')
    puts "tubes: #{tubes_str}"
  end

  def error(line_num, message)
    puts "line #{line_num}: error: #{message}"
  end
end

machine = VendingMachine.new
machine.run
