#!/usr/bin/env ruby

VALID_COINS = [0.05, 0.10, 0.25, 0.50, 1.00, 2.00]

slots = {}          # code -> {name, price, count}
tubes = {}          # coin value -> count
credit = 0.0
inserted_coins = [] # coins inserted in order for current customer
sales = {}          # product name -> {count, revenue}

def valid_slot?(s)
  s =~ /^[A-Z]\d$/
end

def valid_name?(s)
  s =~ /^[a-z]{1,12}$/
end

def valid_money?(s)
  s =~ /^\d+\.\d{2}$/
end

def valid_coin?(v)
  [0.05, 0.10, 0.25, 0.50, 1.00, 2.00].include?(v)
end

def valid_count?(s)
  s =~ /^\d{1,3}$/ && s.to_i <= 999
end

$stdin.each_line.with_index do |line, idx|
  line_num = idx + 1
  line = line.chomp
  next if line.empty?

  fields = line.split
  next if fields.empty?

  cmd = fields[0]
  case cmd
  when "SLOT"
    if fields.size != 6
      puts "line #{line_num}: error: wrong field count"
      next
    end

    code = fields[1]
    name = fields[2]
    price_str = fields[3]
    count_str = fields[4]

    if !valid_slot?(code)
      puts "line #{line_num}: error: bad slot"
      next
    end
    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end
    if !valid_money?(price_str)
      puts "line #{line_num}: error: bad money"
      next
    end
    if !valid_count?(count_str)
      puts "line #{line_num}: error: bad count"
      next
    end

    price = price_str.to_f
    count = count_str.to_i
    slots[code] = {name: name, price: price, count: count}

  when "TUBE"
    if fields.size != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    coin_str = fields[1]
    count_str = fields[2]

    if !valid_money?(coin_str)
      puts "line #{line_num}: error: bad coin"
      next
    end

    coin_value = coin_str.to_f
    if !valid_coin?(coin_value)
      puts "line #{line_num}: error: bad coin"
      next
    end

    if !valid_count?(count_str)
      puts "line #{line_num}: error: bad count"
      next
    end

    count = count_str.to_i
    tubes[coin_value] = (tubes[coin_value] || 0) + count

  when "COIN"
    if fields.size != 2
      puts "line #{line_num}: error: wrong field count"
      next
    end

    coin_str = fields[1]
    if !valid_money?(coin_str)
      puts "line #{line_num}: error: bad money"
      next
    end

    coin_value = coin_str.to_f
    if !valid_coin?(coin_value)
      puts "line #{line_num}: error: bad coin"
      next
    end

    if credit + coin_value > 5.00
      puts "rejected #{format('%.2f', coin_value)} (credit limit)"
      next
    end

    tubes[coin_value] = (tubes[coin_value] || 0) + 1
    credit += coin_value
    inserted_coins << coin_value
    puts "credit #{format('%.2f', credit)}"

  when "SELECT"
    if fields.size != 2
      puts "line #{line_num}: error: wrong field count"
      next
    end

    code = fields[1]

    if !slots[code]
      puts "line #{line_num}: error: no slot #{code}"
      next
    end

    slot = slots[code]
    if slot[:count] == 0
      puts "line #{line_num}: error: sold out #{code}"
      next
    end

    if credit < slot[:price]
      diff = slot[:price] - credit
      puts "line #{line_num}: error: insert #{format('%.2f', diff)} more"
      next
    end

    change = credit - slot[:price]

    # Try to make change
    coin_order = [2.00, 1.00, 0.50, 0.25, 0.10, 0.05]
    change_coins = []
    remaining_change = change
    temp_tubes = tubes.dup

    coin_order.each do |c|
      available = temp_tubes[c] || 0
      needed = (remaining_change / c).to_i
      take = [needed, available].min
      change_coins << c if take > 0
      change_coins.concat([c] * (take - 1)) if take > 1
      remaining_change -= take * c
      temp_tubes[c] = available - take
    end

    if remaining_change.abs > 0.001
      puts "line #{line_num}: error: exact change needed"
      next
    end

    # Perform transaction
    change_coins.sort.reverse.each do |c|
      tubes[c] = (tubes[c] || 0) - 1
    end
    slot[:count] -= 1
    sales[slot[:name]] ||= {count: 0, revenue: 0.0}
    sales[slot[:name]][:count] += 1
    sales[slot[:name]][:revenue] += slot[:price]
    credit = 0
    inserted_coins = []

    if change > 0.001
      change_str = change_coins.map { |c| format('%.2f', c) }.join(' ')
      puts "vend #{slot[:name]}, change #{format('%.2f', change)} [#{change_str}]"
    else
      puts "vend #{slot[:name]}"
    end

  when "CANCEL"
    if fields.size != 1
      puts "line #{line_num}: error: wrong field count"
      next
    end

    if credit < 0.001
      puts "nothing to return"
      next
    end

    # Return coins in order inserted
    returned_str = inserted_coins.map { |c| format('%.2f', c) }.join(' ')
    puts "returned #{format('%.2f', credit)} [#{returned_str}]"

    # Remove from tubes
    inserted_coins.each do |c|
      tubes[c] = (tubes[c] || 0) - 1
    end

    credit = 0
    inserted_coins = []

  else
    puts "line #{line_num}: error: unknown command"
  end
end

# Final report
if credit > 0.001
  puts "credit #{format('%.2f', credit)} kept"
end

puts "sales:"
if sales.empty?
  puts "  none"
else
  sales.sort_by { |name, data| [-data[:revenue], name] }.each do |name, data|
    puts format("  %-12s %3d %8s", name, data[:count], format('%.2f', data[:revenue]))
  end
end

tube_str = VALID_COINS.map { |c| "#{format('%.2f', c)}x#{tubes[c] || 0}" }.join(' ')
puts "tubes: #{tube_str}"
