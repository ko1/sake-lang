#!/usr/bin/env ruby

require 'rational'

# Parse SERVES line
first_line = $stdin.gets.chomp

if first_line !~ /^SERVES\s+(\d+)\s+->\s+(\d+)$/
  puts "line 1: error: bad servings"
  exit
end

n = $1.to_i
m = $2.to_i
factor = Rational(m, n)

def parse_quantity(s)
  # Try integer
  if s =~ /^\d+$/
    return Rational(s.to_i)
  end

  # Try decimal
  if s =~ /^(\d+)\.(\d+)$/
    int_part = $1.to_i
    dec_part = $2
    # Convert to fraction: "1.5" -> 15/10 -> 3/2
    denom = 10 ** dec_part.length
    return Rational(int_part * denom + dec_part.to_i, denom)
  end

  # Try fraction
  if s =~ /^(\d+)\/(\d+)$/
    num = $1.to_i
    denom = $2.to_i
    return denom == 0 ? nil : Rational(num, denom)
  end

  nil
end

def format_quantity(q)
  # Reduce fraction
  reduced = q.rationalize
  num = reduced.numerator
  denom = reduced.denominator

  # Check if denominator is small enough for fraction display
  if denom <= 8
    if num % denom == 0
      return num / denom
    elsif num > denom
      whole = num / denom
      remainder = num % denom
      return "#{whole} #{remainder}/#{denom}"
    else
      return "#{num}/#{denom}"
    end
  else
    # Use decimal with 2 places
    return format('%.2f', num.to_f / denom)
  end
end

units = {
  'tsp' => {group: :spoon, to_base: 1},
  'tbsp' => {group: :spoon, to_base: 3},
  'cup' => {group: :spoon, to_base: 48},
  'g' => {group: :gram, to_base: 1},
  'kg' => {group: :gram, to_base: 1000},
  'ml' => {group: :ml, to_base: 1},
  'l' => {group: :ml, to_base: 1000},
  '-' => {group: :count, to_base: 1}
}

ingredients = []  # [{name, unit_group, unit_base, qty}]
seen_keys = {}    # {(name, group) => index}

# Output header
puts "serves #{m} (x #{format_quantity(factor)})"

line_num = 1
$stdin.each_line do |line|
  line_num += 1
  line = line.chomp
  next if line.empty? || line.start_with?('#')

  fields = line.split

  if fields.empty?
    next
  end

  # Parse quantity (could be 1 or 2 fields for mixed numbers)
  qty = nil
  qty_consumed = 0

  # First, try to parse first field as quantity
  q1 = parse_quantity(fields[0])
  if q1 && q1 > 0
    qty = q1
    qty_consumed = 1

    # Check if next field is a fraction (mixed number)
    if fields.size > 1
      q2 = parse_quantity(fields[1])
      if q2 && q2 < 1
        qty = qty + q2
        qty_consumed = 2
      end
    end
  end

  if qty.nil? || qty <= 0
    puts "line #{line_num}: error: bad quantity"
    next
  end

  # Parse unit
  if fields.size <= qty_consumed
    puts "line #{line_num}: error: missing unit"
    next
  end

  unit = fields[qty_consumed]
  if !units[unit]
    puts "line #{line_num}: error: unknown unit #{unit}"
    next
  end

  # Parse name
  if fields.size <= qty_consumed + 1
    puts "line #{line_num}: error: missing name"
    next
  end

  name_parts = fields[qty_consumed + 1..-1]
  name = name_parts.join(' ')

  # Scale quantity
  scaled_qty = qty * factor

  # Group by (name, unit_group)
  group = units[unit][:group]
  key = [name, group]

  if seen_keys[key]
    idx = seen_keys[key]
    ingredients[idx][:qty] += scaled_qty
  else
    seen_keys[key] = ingredients.size
    ingredients << {
      name: name,
      group: group,
      unit: unit,
      qty: scaled_qty,
      unit_base: units[unit][:to_base]
    }
  end
end

# Output ingredients
ingredients.each do |ing|
  name = ing[:name]
  group = ing[:group]
  qty = ing[:qty]

  if group == :count
    # Round up for counts
    display_qty = (qty.numerator + qty.denominator - 1) / qty.denominator
    puts "#{display_qty} #{name}"
  elsif group == :spoon
    # Convert to base unit (tsp)
    qty_tsp = qty * ing[:unit_base]

    # Choose unit
    qty_cup = qty_tsp / 48
    qty_tbsp = qty_tsp / 3

    chosen_unit = 'tsp'
    display_qty = qty_tsp

    if qty_cup >= 1 && qty_cup.denominator <= 4
      chosen_unit = 'cup'
      display_qty = qty_cup
    elsif qty_tbsp >= 1 && qty_tbsp.denominator <= 4
      chosen_unit = 'tbsp'
      display_qty = qty_tbsp
    end

    puts "#{format_quantity(display_qty)} #{chosen_unit} #{name}"
  elsif group == :gram
    # Check if should use kg
    qty_g = qty * ing[:unit_base]
    if qty_g >= 1000
      chosen_unit = 'kg'
      display_qty = qty_g / 1000
    else
      chosen_unit = 'g'
      display_qty = qty_g
    end

    puts "#{format_quantity(display_qty)} #{chosen_unit} #{name}"
  elsif group == :ml
    # Check if should use l
    qty_ml = qty * ing[:unit_base]
    if qty_ml >= 1000
      chosen_unit = 'l'
      display_qty = qty_ml / 1000
    else
      chosen_unit = 'ml'
      display_qty = qty_ml
    end

    puts "#{format_quantity(display_qty)} #{chosen_unit} #{name}"
  end
end
