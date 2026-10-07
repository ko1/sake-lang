#!/usr/bin/env ruby

class VendingMachine
  COINS = [0.05, 0.10, 0.25, 0.50, 1.00, 2.00].freeze
  COIN_STRINGS = ['0.05', '0.10', '0.25', '0.50', '1.00', '2.00'].freeze

  def initialize
    @slots = {}
    @tubes = { 0.05 => 0, 0.10 => 0, 0.25 => 0, 0.50 => 0, 1.00 => 0, 2.00 => 0 }
    @credit = 0.0
    @coin_history = []
    @sales = {}
  end

  def run
    line_num = 0
    STDIN.each_line do |line|
      line_num += 1
      line.strip!
      next if line.empty?

      parts = line.split

      command = parts[0]
      case command
      when 'SLOT'
        handle_slot(line_num, parts)
      when 'TUBE'
        handle_tube(line_num, parts)
      when 'COIN'
        handle_coin(line_num, parts)
      when 'SELECT'
        handle_select(line_num, parts)
      when 'CANCEL'
        handle_cancel(line_num, parts)
      else
        puts "line #{line_num}: error: unknown command"
      end
    end

    print_report
  end

  def handle_slot(line_num, parts)
    if parts.size != 5
      puts "line #{line_num}: error: wrong field count"
      return
    end

    code = parts[1]
    name = parts[2]
    price_str = parts[3]
    count_str = parts[4]

    if !valid_slot_code?(code)
      puts "line #{line_num}: error: bad slot"
      return
    end
    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      return
    end
    if !valid_money?(price_str)
      puts "line #{line_num}: error: bad money"
      return
    end
    if !valid_count?(count_str)
      puts "line #{line_num}: error: bad count"
      return
    end

    price = price_str.to_f
    count = count_str.to_i
    @slots[code] = { name: name, price: price, count: count }
  end

  def handle_tube(line_num, parts)
    if parts.size != 3
      puts "line #{line_num}: error: wrong field count"
      return
    end

    coin_str = parts[1]
    count_str = parts[2]

    if !COIN_STRINGS.include?(coin_str)
      puts "line #{line_num}: error: bad coin"
      return
    end
    if !valid_count?(count_str)
      puts "line #{line_num}: error: bad count"
      return
    end

    coin = coin_str.to_f
    count = count_str.to_i
    @tubes[coin] += count
  end

  def handle_coin(line_num, parts)
    if parts.size != 2
      puts "line #{line_num}: error: wrong field count"
      return
    end

    coin_str = parts[1]

    if !valid_money?(coin_str)
      puts "line #{line_num}: error: bad money"
      return
    end

    coin = coin_str.to_f
    if !COIN_STRINGS.include?(coin_str)
      puts "rejected #{coin_str}"
      return
    end

    if @credit + coin > 5.0
      puts "rejected #{coin_str} (credit limit)"
      return
    end

    @tubes[coin] += 1
    @coin_history << coin
    @credit += coin
    puts "credit #{format_money(@credit)}"
  end

  def handle_select(line_num, parts)
    if parts.size != 2
      puts "line #{line_num}: error: wrong field count"
      return
    end

    code = parts[1]

    if !@slots[code]
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
      puts "insert #{format_money(diff)} more"
      return
    end

    change = @credit - slot[:price]
    change_coins = make_change(change)

    if change_coins.nil?
      puts "exact change needed"
      return
    end

    slot[:count] -= 1
    change_coins.each { |c| @tubes[c] -= 1 }
    @credit = 0.0
    @coin_history = []

    @sales[slot[:name]] ||= { count: 0, revenue: 0.0 }
    @sales[slot[:name]][:count] += 1
    @sales[slot[:name]][:revenue] += slot[:price]

    if change > 0
      change_str = change_coins.map { |c| format_money(c) }.join(" ")
      puts "vend #{slot[:name]}, change #{format_money(change)} [#{change_str}]"
    else
      puts "vend #{slot[:name]}"
    end
  end

  def handle_cancel(line_num, parts)
    if parts.size != 1
      puts "line #{line_num}: error: wrong field count"
      return
    end

    if @credit == 0.0
      puts "nothing to return"
      return
    end

    returned_coins = @coin_history.dup
    total_returned = returned_coins.sum
    returned_coins.each { |c| @tubes[c] -= 1 }
    @credit = 0.0
    @coin_history = []

    coins_str = returned_coins.map { |c| format_money(c) }.join(" ")
    puts "returned #{format_money(total_returned)} [#{coins_str}]"
  end

  def make_change(amount)
    return [] if amount == 0.0

    amount_cents = (amount * 100).round
    result = []
    tubes_copy = @tubes.dup

    COINS.reverse.each do |coin|
      coin_cents = (coin * 100).round
      count = [tubes_copy[coin], amount_cents / coin_cents].min
      count.times do
        result << coin
        amount_cents -= coin_cents
      end
    end

    return nil if amount_cents != 0
    result
  end

  def valid_slot_code?(code)
    /^[A-Z]\d$/.match?(code)
  end

  def valid_name?(name)
    /^[a-z]{1,12}$/.match?(name)
  end

  def valid_money?(str)
    /^\d+\.\d{2}$/.match?(str) && str.to_f > 0
  end

  def valid_count?(str)
    /^\d+$/.match?(str)
  end

  def format_money(amount)
    format("%.2f", amount)
  end

  def print_report
    if @credit != 0.0
      puts "credit #{format_money(@credit)} kept"
    end

    puts "sales:"
    if @sales.empty?
      puts "  none"
    else
      sorted_sales = @sales.sort_by { |name, data| [-data[:revenue], name] }
      sorted_sales.each do |name, data|
        puts format("  %-12s %3d %8s", name, data[:count], format_money(data[:revenue]))
      end
    end

    tube_str = COINS.map { |coin| "#{format_money(coin)}x#{@tubes[coin]}" }.join(" ")
    puts "tubes: #{tube_str}"
  end
end

machine = VendingMachine.new
machine.run
