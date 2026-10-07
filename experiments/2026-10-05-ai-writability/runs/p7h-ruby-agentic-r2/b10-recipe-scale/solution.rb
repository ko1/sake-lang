#!/usr/bin/env ruby

class RecipeScaler
  UNITS = {
    'tsp' => {group: 'spoons', to_tsp: Rational(1)},
    'tbsp' => {group: 'spoons', to_tsp: Rational(3)},
    'cup' => {group: 'spoons', to_tsp: Rational(48)},
    'g' => {group: 'grams', to_base: Rational(1)},
    'kg' => {group: 'grams', to_base: Rational(1000)},
    'ml' => {group: 'millilitres', to_base: Rational(1)},
    'l' => {group: 'millilitres', to_base: Rational(1000)},
    '-' => {group: 'count', to_base: Rational(1)}
  }

  def initialize
    @n = nil
    @m = nil
    @factor = nil
    @ingredients = []  # [{name:, unit:, group:, amount:, order:}, ...]
    @order_counter = 0
  end

  def run
    line_num = 0
    first_line = true

    STDIN.each_line do |line|
      line_num += 1
      line = line.strip
      next if line.empty? || line.start_with?('#')

      if first_line
        first_line = false
        unless process_servings(line, line_num)
          return
        end
      else
        process_ingredient(line, line_num)
      end
    end

    # If no ingredients were processed, print_output won't print anything
    print_output if @factor
  end

  private

  def process_servings(line, line_num)
    parts = line.split
    if parts.size != 4 || parts[0] != 'SERVES' || parts[2] != '->'
      puts "line #{line_num}: error: bad servings"
      return false
    end

    n = parts[1].to_i
    m = parts[3].to_i

    if n <= 0 || n > 100 || m <= 0 || m > 100
      puts "line #{line_num}: error: bad servings"
      return false
    end

    @n = n
    @m = m
    @factor = Rational(m, n)

    # Print serves line immediately
    factor_str = quantity_to_str(@factor)
    puts "serves #{@m} (x #{factor_str})"

    true
  end

  def process_ingredient(line, line_num)
    parts = line.split

    return error(line_num, "bad quantity") if parts.size < 1

    quantity_str = parts[0]
    quantity = parse_quantity(quantity_str, parts[1], line_num)
    return if quantity.nil?

    unit_idx = 1
    # Check for mixed number (2 quantity fields)
    if quantity_str.match?(/^\d+$/) && parts.size > 1 && parts[1].match?(/^[0-9]+\/[0-9]+$/)
      frac_qty = parse_quantity(parts[1], nil, line_num)
      if frac_qty
        quantity += frac_qty
        unit_idx = 2
      end
    end

    return error(line_num, "missing unit") if parts.size <= unit_idx

    unit = parts[unit_idx]
    return error(line_num, "unknown unit #{unit}") unless UNITS[unit]

    return error(line_num, "missing name") if parts.size <= unit_idx + 1

    name = parts[unit_idx + 1..-1].join(' ')

    group = UNITS[unit][:group]
    scaled_qty = quantity * @factor

    # Convert to base unit for the group
    base_amount = case group
                  when 'spoons'
                    scaled_qty * UNITS[unit][:to_tsp]
                  when 'grams'
                    scaled_qty * UNITS[unit][:to_base]
                  when 'millilitres'
                    scaled_qty * UNITS[unit][:to_base]
                  when 'count'
                    scaled_qty
                  end

    # Store ingredient
    existing = @ingredients.find { |ing| ing[:name] == name && ing[:group] == group }

    if existing
      existing[:amount] += base_amount
    else
      @ingredients << {
        name: name,
        group: group,
        amount: base_amount,
        order: @order_counter
      }
      @order_counter += 1
    end
  end

  def parse_quantity(str, next_str, line_num)
    # Integer
    if str.match?(/^\d+$/)
      num = str.to_i
      return error(line_num, "bad quantity") if num <= 0
      return Rational(num)
    end

    # Decimal
    if str.match?(/^\d+\.\d+$/)
      parts = str.split('.')
      whole = parts[0].to_i
      frac_part = parts[1]
      denom = 10 ** frac_part.length
      numer = whole * denom + frac_part.to_i
      return error(line_num, "bad quantity") if numer <= 0
      return Rational(numer, denom)
    end

    # Fraction
    if str.match?(/^(\d+)\/(\d+)$/)
      match = str.match(/^(\d+)\/(\d+)$/)
      num = match[1].to_i
      denom = match[2].to_i

      return error(line_num, "bad quantity") if denom == 0 || num == 0

      return Rational(num, denom)
    end

    error(line_num, "bad quantity")
    nil
  end

  def print_output
    @ingredients.sort_by { |ing| ing[:order] }.each do |ing|
      if ing[:group] == 'count'
        # Round up for counts
        display_qty = (ing[:amount].numerator + ing[:amount].denominator - 1) / ing[:amount].denominator
        puts "#{display_qty} #{ing[:name]}"
      else
        unit = choose_unit(ing[:group], ing[:amount])
        amount_in_unit = convert_to_unit(ing[:amount], ing[:group], unit)
        qty_str = quantity_to_str(amount_in_unit)
        puts "#{qty_str} #{unit} #{ing[:name]}"
      end
    end
  end

  def choose_unit(group, amount)
    case group
    when 'spoons'
      amount_in_cup = amount / Rational(48)
      if amount_in_cup >= 1 && amount_in_cup.denominator <= 4
        return 'cup'
      end

      amount_in_tbsp = amount / Rational(3)
      if amount_in_tbsp >= 1 && amount_in_tbsp.denominator <= 4
        return 'tbsp'
      end

      return 'tsp'

    when 'grams'
      if amount >= 1000
        return 'kg'
      else
        return 'g'
      end

    when 'millilitres'
      if amount >= 1000
        return 'l'
      else
        return 'ml'
      end

    when 'count'
      return '-'
    end
  end

  def convert_to_unit(amount, group, target_unit)
    case group
    when 'spoons'
      # amount is in tsp, convert to target
      case target_unit
      when 'tsp'
        amount
      when 'tbsp'
        amount / Rational(3)
      when 'cup'
        amount / Rational(48)
      end

    when 'grams'
      case target_unit
      when 'g'
        amount
      when 'kg'
        amount / Rational(1000)
      end

    when 'millilitres'
      case target_unit
      when 'ml'
        amount
      when 'l'
        amount / Rational(1000)
      end

    when 'count'
      amount
    end
  end

  def quantity_to_str(qty)
    # Rational is already in reduced form

    # If denominator > 8, use decimal
    if qty.denominator > 8
      # Round half up to 2 decimals
      decimal = qty.to_f
      result = (decimal * 100).round / 100.0
      return format('%.2f', result)
    end

    # Mixed number or proper fraction
    if qty >= 1
      whole = qty.to_i
      frac = qty - whole
      if frac == 0
        return whole.to_s
      else
        return "#{whole} #{frac.numerator}/#{frac.denominator}"
      end
    else
      return "#{qty.numerator}/#{qty.denominator}"
    end
  end

  def error(line_num, msg)
    puts "line #{line_num}: error: #{msg}"
    nil
  end
end

scaler = RecipeScaler.new
scaler.run
