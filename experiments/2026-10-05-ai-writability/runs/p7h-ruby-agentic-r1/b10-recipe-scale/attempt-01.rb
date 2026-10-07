require 'rational'

class RecipeScaler
  UNITS = {
    'tsp' => {group: :spoons, base_tsp: 1},
    'tbsp' => {group: :spoons, base_tsp: 3},
    'cup' => {group: :spoons, base_tsp: 48},
    'g' => {group: :grams, base_g: 1},
    'kg' => {group: :grams, base_g: 1000},
    'ml' => {group: :ml, base_ml: 1},
    'l' => {group: :ml, base_ml: 1000},
    '-' => {group: :count, base: 1}
  }

  def initialize
    @factor = nil
    @ingredients = {}  # (name, group) -> {unit, quantity}
    @order = []  # (name, group) in order
    @line_num = 0
  end

  def run(input)
    lines = input.split("\n")

    # Process first line
    @line_num = 1
    first_line = lines[0].strip
    unless parse_serves(first_line)
      puts "line 1: error: bad servings"
      return
    end

    # Process ingredients
    (1...lines.length).each do |i|
      @line_num = i + 1
      line = lines[i].strip
      next if line.empty? || line.start_with?('#')

      process_ingredient(line)
    end

    output_recipe
  end

  private

  def parse_serves(line)
    parts = line.split
    return false unless parts.length == 4
    return false unless parts[0] == 'SERVES'
    return false unless parts[2] == '->'

    n = parts[1].to_i
    m = parts[3].to_i
    return false if n <= 0 || n > 100 || m <= 0 || m > 100

    @factor = Rational(m, n)
    true
  end

  def parse_quantity(qty_str)
    # Try to parse as integer
    if qty_str =~ /^\d+$/
      return Rational(qty_str.to_i)
    end

    # Try to parse as decimal
    if qty_str =~ /^\d+\.\d+$/
      parts = qty_str.split('.')
      int_part = parts[0].to_i
      frac_part = parts[1]
      decimal = Rational(frac_part.to_i, 10**frac_part.length)
      return Rational(int_part) + decimal
    end

    # Try to parse as fraction
    if qty_str =~ /^\d+\/\d+$/
      num, denom = qty_str.split('/').map(&:to_i)
      return false if denom == 0
      return Rational(num, denom)
    end

    false
  end

  def parse_mixed_quantity(parts, start_idx)
    # parts[start_idx] is the first field
    qty1 = parse_quantity(parts[start_idx])
    return false unless qty1

    # If next part is a fraction, it's a mixed number
    if start_idx + 1 < parts.length && parts[start_idx + 1] =~ /^\d+\/\d+$/
      qty2 = parse_quantity(parts[start_idx + 1])
      return false unless qty2
      return qty1 + qty2, start_idx + 2
    end

    return qty1, start_idx + 1
  end

  def process_ingredient(line)
    parts = line.split

    # Parse quantity (which might be mixed)
    result = parse_mixed_quantity(parts, 0)
    unless result
      puts "line #{@line_num}: error: bad quantity"
      return
    end
    qty, next_idx = result

    # Check if quantity is positive
    if qty <= 0
      puts "line #{@line_num}: error: bad quantity"
      return
    end

    # Parse unit
    if next_idx >= parts.length
      puts "line #{@line_num}: error: missing unit"
      return
    end

    unit = parts[next_idx]
    unless UNITS[unit]
      puts "line #{@line_num}: error: unknown unit #{unit}"
      return
    end

    # Parse name
    name_parts = parts[(next_idx + 1)..-1]
    if name_parts.empty?
      puts "line #{@line_num}: error: missing name"
      return
    end

    name = name_parts.join(' ')
    group = UNITS[unit][:group]

    # Scale quantity
    scaled_qty = qty * @factor

    # Add to ingredients
    key = [name, group]
    if @ingredients[key]
      @ingredients[key][:quantity] += scaled_qty
    else
      @ingredients[key] = {unit: unit, quantity: scaled_qty}
      @order.push(key)
    end
  end

  def output_recipe
    # Output serves line
    puts "serves #{@factor.denominator} (x #{format_quantity(@factor)})"

    # Output ingredients
    @order.each do |name, group|
      info = @ingredients[[name, group]]
      unit = info[:unit]
      qty = info[:quantity]

      # Choose appropriate unit
      case group
      when :spoons
        qty_tsp = qty * UNITS[unit][:base_tsp]
        unit = choose_spoon_unit(qty_tsp)
        qty = qty_tsp / Rational(UNITS[unit][:base_tsp])
      when :grams
        qty_g = qty * UNITS[unit][:base_g]
        if qty_g >= 1000
          unit = 'kg'
          qty = qty_g / 1000
        else
          unit = 'g'
          qty = qty_g
        end
      when :ml
        qty_ml = qty * UNITS[unit][:base_ml]
        if qty_ml >= 1000
          unit = 'l'
          qty = qty_ml / 1000
        else
          unit = 'ml'
          qty = qty_ml
        end
      when :count
        qty = (qty + Rational(1,2)).floor  # Round up
        unit = ''
      end

      # Format output
      qty_str = format_quantity(qty)
      if unit == ''
        puts "#{qty_str} #{name}"
      else
        puts "#{qty_str} #{unit} #{name}"
      end
    end
  end

  def choose_spoon_unit(qty_tsp)
    # Try cup first
    cup_qty = qty_tsp / 48
    if cup_qty >= 1 && cup_qty.denominator <= 4
      return 'cup'
    end

    # Try tbsp
    tbsp_qty = qty_tsp / 3
    if tbsp_qty >= 1 && tbsp_qty.denominator <= 4
      return 'tbsp'
    end

    # Default to tsp
    'tsp'
  end

  def format_quantity(qty)
    # Reduce fraction
    qty = qty.reduce

    # If denominator is > 8, use decimal
    if qty.denominator > 8
      decimal = qty.to_f
      return format('%.2f', decimal)
    end

    # If whole number
    if qty.denominator == 1
      return qty.numerator.to_s
    end

    # If it has a whole part, show as mixed number
    if qty > 1
      whole = qty.numerator / qty.denominator
      remainder = qty.numerator % qty.denominator
      if remainder == 0
        return whole.to_s
      else
        return "#{whole} #{remainder}/#{qty.denominator}"
      end
    end

    # Otherwise show as fraction
    "#{qty.numerator}/#{qty.denominator}"
  end
end

scaler = RecipeScaler.new
scaler.run(STDIN.read)
