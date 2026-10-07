#!/usr/bin/env ruby

class BillOfMaterials
  def initialize
    @parts = {}
    @assemblies = {}
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
      when 'PART'
        handle_part(line_num, parts)
      when 'ASSY'
        handle_assy(line_num, parts)
      when 'BUILD'
        handle_build(line_num, parts)
      else
        puts "line #{line_num}: error: unknown command"
      end
    end
  end

  def handle_part(line_num, parts)
    if parts.size != 3
      puts "line #{line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    cost_str = parts[2]

    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      return
    end
    if !valid_money?(cost_str)
      puts "line #{line_num}: error: bad cost"
      return
    end
    if @parts[name] || @assemblies[name]
      puts "line #{line_num}: error: duplicate #{name}"
      return
    end

    @parts[name] = cost_str.to_f
  end

  def handle_assy(line_num, parts)
    if parts.size < 4
      puts "line #{line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    labor_str = parts[2]

    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      return
    end
    if !valid_money?(labor_str)
      puts "line #{line_num}: error: bad cost"
      return
    end
    if @parts[name] || @assemblies[name]
      puts "line #{line_num}: error: duplicate #{name}"
      return
    end

    components = []
    seen_names = Set.new

    (3...parts.size).each do |i|
      comp_text = parts[i]
      comp_parts = comp_text.split(':')
      if comp_parts.size != 2
        puts "line #{line_num}: error: bad component #{comp_text}"
        return
      end

      comp_name = comp_parts[0]
      qty_str = comp_parts[1]

      if !valid_name?(comp_name)
        puts "line #{line_num}: error: bad component #{comp_text}"
        return
      end
      if !valid_qty_component?(qty_str)
        puts "line #{line_num}: error: bad component #{comp_text}"
        return
      end

      if seen_names.include?(comp_name)
        puts "line #{line_num}: error: repeated component #{comp_name}"
        return
      end
      seen_names.add(comp_name)

      components << [comp_name, qty_str.to_i]
    end

    @assemblies[name] = {
      labor: labor_str.to_f,
      components: components
    }
  end

  def handle_build(line_num, parts)
    if parts.size != 3
      puts "line #{line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    qty_str = parts[2]

    if !valid_qty_build?(qty_str)
      puts "line #{line_num}: error: bad quantity"
      return
    end

    qty = qty_str.to_i

    if !@parts[name] && !@assemblies[name]
      puts "line #{line_num}: cannot build: unknown item #{name}"
      return
    end

    result = build_item(name, qty, [])
    if result.is_a?(String)
      puts "line #{line_num}: cannot build: #{result}"
      return
    end

    tree, parts_list = result
    print_tree(tree)
    print_parts(parts_list)
  end

  def build_item(name, qty, path)
    if path.include?(name)
      cycle_str = (path + [name]).join(" > ")
      return cycle_str
    end

    if !@parts[name] && !@assemblies[name]
      parent = path.last
      if parent
        return "unknown item #{name} in #{parent}"
      else
        return "unknown item #{name}"
      end
    end

    if @parts[name]
      unit_cost = @parts[name]
      total_cost = unit_cost * qty
      return [[name, qty, total_cost], { name => qty }]
    end

    assy = @assemblies[name]
    all_parts = {}
    children = []

    assy[:components].each do |comp_name, comp_qty|
      comp_total_qty = comp_qty * qty
      result = build_item(comp_name, comp_total_qty, path + [name])
      if result.is_a?(String)
        return result
      end

      sub_tree, sub_parts = result
      children << sub_tree
      sub_parts.each { |pname, pqty| all_parts[pname] = (all_parts[pname] || 0) + pqty }
    end

    component_cost = children.reduce(0.0) { |sum, child| sum + child[2] }
    total_cost = assy[:labor] * qty + component_cost

    return [[name, qty, total_cost, children], all_parts]
  end

  def print_tree(tree, indent = 0)
    if tree.is_a?(Array) && tree.length >= 3
      name, qty, cost = tree[0], tree[1], tree[2]
      prefix = " " * indent
      puts "#{prefix}#{qty} x #{name} = #{format('%.2f', cost)}"

      if tree.length > 3
        tree[3].each { |child| print_tree(child, indent + 2) }
      end
    end
  end

  def print_parts(parts_list)
    puts "parts:"
    if parts_list.empty?
      puts "  none"
    else
      sorted = parts_list.sort_by { |name, qty| [-qty, name] }
      sorted.each do |name, qty|
        cost = @parts[name] * qty
        puts format("  %s x%d = %.2f", name, qty, cost)
      end
    end
  end

  def valid_name?(name)
    /^[a-z][a-z0-9_]{0,15}$/.match?(name)
  end

  def valid_money?(str)
    /^\d+\.\d{2}$/.match?(str)
  end

  def valid_qty_component?(str)
    /^[1-9]\d{0,2}$/.match?(str) && str.to_i <= 999
  end

  def valid_qty_build?(str)
    /^[1-9]\d{0,3}$/.match?(str) && str.to_i <= 1000
  end
end

bom = BillOfMaterials.new
bom.run
