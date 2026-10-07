#!/usr/bin/env ruby

class RecipeScaler
  UNIT_GROUPS = {
    'tsp' => :spoons,
    'tbsp' => :spoons,
    'cup' => :spoons,
    'g' => :grams,
    'kg' => :grams,
    'ml' => :ml,
    'l' => :ml,
    '-' => :count
  }

  def initialize
    @factor = nil
    @target_servings = nil
    @ingredients = []
  end

  def run
    line_num = 0
    first_line = true

    STDIN.each_line do |line|
      line_num += 1
      line.strip!
      next if line.empty?
      next if line.start_with?('#')

      if first_line
        first_line = false
        if !parse_serves(line_num, line)
          return
        end
        next
      end

      parse_ingredient(line_num, line)
    end

    print_output
  end

  def parse_serves(line_num, line)
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

    @factor = Rational(m, n)
    @target_servings = m
    true
  end

  def parse_ingredient(line_num, line)
    parts = line.split
    return if parts.empty?

    quantity = nil
    unit_idx = 1
    unit = nil

    qty_str = parts[0]
    if qty_str.include?('/')
      nums = qty_str.split('/')
      if nums.size != 2
        puts "line #{line_num}: error: bad quantity"
        return
      end
      num = nums[0].to_i rescue 0
      denom = nums[1].to_i rescue 0
      if denom == 0 || num <= 0
        puts "line #{line_num}: error: bad quantity"
        return
      end
      quantity = Rational(num, denom)
      unit_idx = 1
    elsif qty_str.include?('.')
      qty_f = qty_str.to_f
      if qty_f <= 0
        puts "line #{line_num}: error: bad quantity"
        return
      end
      quantity = qty_f.to_r
      unit_idx = 1
    else
      num = qty_str.to_i
      if num <= 0
        puts "line #{line_num}: error: bad quantity"
        return
      end
      if parts.size > 2 && parts[1].include?('/')
        frac_str = parts[1]
        frac_parts = frac_str.split('/')
        if frac_parts.size == 2
          frac_num = frac_parts[0].to_i rescue 0
          frac_denom = frac_parts[1].to_i rescue 0
          if frac_denom > 0 && frac_num > 0
            quantity = Rational(num) + Rational(frac_num, frac_denom)
            unit_idx = 2
          end
        end
      end
      quantity ||= Rational(num)
    end

    if !quantity || quantity <= 0
      puts "line #{line_num}: error: bad quantity"
      return
    end

    if unit_idx >= parts.size
      puts "line #{line_num}: error: missing unit"
      return
    end

    unit = parts[unit_idx]

    if !UNIT_GROUPS[unit]
      puts "line #{line_num}: error: unknown unit #{unit}"
      return
    end

    name_start = unit_idx + 1
    if name_start >= parts.size
      puts "line #{line_num}: error: missing name"
      return
    end

    name = parts[name_start..-1].join(' ')
    group = UNIT_GROUPS[unit]
    scaled_qty = quantity * @factor

    @ingredients << {
      name: name,
      unit: unit,
      group: group,
      qty: scaled_qty
    }
  end

  def print_output
    puts "serves #{@target_servings} (x #{format_quantity(@factor)})"

    grouped = {}
    order = []

    @ingredients.each do |ing|
      key = [ing[:name], ing[:group]]
      if !grouped[key]
        grouped[key] = Rational(0)
        order << key
      end
      grouped[key] += to_base_unit(ing[:qty], ing[:unit])
    end

    order.each do |name, group|
      base_qty = grouped[[name, group]]

      case group
      when :spoons
        unit, output_qty = best_spoon_unit(base_qty)
        puts "#{format_quantity(output_qty)} #{unit} #{name}"
      when :grams
        unit, output_qty = best_gram_unit(base_qty)
        puts "#{format_quantity(output_qty)} #{unit} #{name}"
      when :ml
        unit, output_qty = best_ml_unit(base_qty)
        puts "#{format_quantity(output_qty)} #{unit} #{name}"
      when :count
        puts "#{base_qty.ceil} #{name}"
      end
    end
  end

  def to_base_unit(qty, unit)
    case unit
    when 'cup'
      qty * Rational(48)
    when 'tbsp'
      qty * Rational(3)
    when 'tsp'
      qty
    when 'kg'
      qty * Rational(1000)
    when 'g'
      qty
    when 'l'
      qty * Rational(1000)
    when 'ml'
      qty
    when '-'
      qty
    else
      qty
    end
  end

  def best_spoon_unit(qty_tsp)
    qty_cup = qty_tsp / Rational(48)
    qty_tbsp = qty_tsp / Rational(3)

    if qty_cup >= 1 && qty_cup.denominator <= 4
      [qty_cup, 'cup']
    elsif qty_tbsp >= 1 && qty_tbsp.denominator <= 4
      [qty_tbsp, 'tbsp']
    else
      [qty_tsp, 'tsp']
    end
  end

  def best_gram_unit(qty)
    if qty >= 1000
      [qty / Rational(1000), 'kg']
    else
      [qty, 'g']
    end
  end

  def best_ml_unit(qty)
    if qty >= 1000
      [qty / Rational(1000), 'l']
    else
      [qty, 'ml']
    end
  end

  def format_quantity(q)
    if q.denominator <= 8
      whole = q.numerator / q.denominator
      remainder = q.numerator % q.denominator
      if remainder == 0
        whole.to_s
      elsif whole == 0
        "#{q.numerator}/#{q.denominator}"
      else
        "#{whole} #{remainder}/#{q.denominator}"
      end
    else
      format("%.2f", q.to_f)
    end
  end
end

scaler = RecipeScaler.new
scaler.run
