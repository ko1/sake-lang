#!/usr/bin/env ruby

class BOM
  def initialize
    @parts = {}  # name => cost
    @assemblies = {}  # name => {labor:, components: [{name:, qty:}, ...]}
    @line_num = 0
  end

  def run
    STDIN.each_line do |line|
      @line_num += 1
      line = line.strip
      next if line.empty?

      process_line(line)
    end
  end

  private

  def process_line(line)
    parts = line.split
    return error("unknown command") if parts.empty?

    command = parts[0]

    case command
    when "PART"
      return error("wrong field count") if parts.size != 3
      process_part(parts)
    when "ASSY"
      return error("wrong field count") if parts.size < 4
      process_assy(parts)
    when "BUILD"
      return error("wrong field count") if parts.size != 3
      process_build(parts)
    else
      error("unknown command")
    end
  end

  def validate_name(name)
    name.match?(/^[a-z][a-z0-9_]{0,15}$/)
  end

  def validate_cost(cost)
    cost.match?(/^\d+\.\d{2}$/) && cost.to_f > 0
  end

  def process_part(parts)
    name = parts[1]
    cost = parts[2]

    return unless validate_name(name) && error_msg("bad name")
    return unless validate_cost(cost) && error_msg("bad cost")
    return if duplicate_item(name)

    @parts[name] = cost.to_f
  end

  def process_assy(parts)
    name = parts[1]
    labor = parts[2]
    components_raw = parts[3..-1]

    return unless validate_name(name) && error_msg("bad name")
    return unless validate_cost(labor) && error_msg("bad cost")
    return if duplicate_item(name)

    components = []
    seen_names = Set.new

    components_raw.each do |comp_str|
      match = comp_str.match(/^(.+):(\d+)$/)
      unless match
        error("bad component #{comp_str}")
        return
      end

      comp_name = match[1]
      comp_qty = match[2].to_i

      return unless validate_component(comp_name, comp_qty)

      if seen_names.include?(comp_name)
        error("repeated component #{comp_name}")
        return
      end

      seen_names.add(comp_name)
      components << {name: comp_name, qty: comp_qty}
    end

    @assemblies[name] = {labor: labor.to_f, components: components}
  end

  def validate_component(name, qty)
    return false unless qty >= 1 && qty <= 999
    error("bad component #{qty}") if qty == 0
    error("bad quantity") if qty < 1 || qty > 999
    true
  end

  def duplicate_item(name)
    if @parts[name] || @assemblies[name]
      error("duplicate #{name}")
      return true
    end
    false
  end

  def process_build(parts)
    name = parts[1]
    qty = parts[2].to_i

    return unless qty >= 1 && qty <= 1000
    error("bad quantity") if qty < 1 || qty > 1000

    unless @parts[name] || @assemblies[name]
      puts "line #{@line_num}: cannot build: unknown item #{name}"
      return
    end

    # Try to build and check for cycles
    tree = []
    path = []
    cycle = build_tree(name, qty, tree, path)

    if cycle
      puts "line #{@line_num}: cannot build: #{cycle}"
      return
    end

    # Print tree
    print_tree(tree, 0)

    # Collect parts
    parts_count = {}
    collect_parts(tree, parts_count)

    # Print parts
    puts "parts:"
    if parts_count.empty?
      # parts_count should never be empty if tree is printed
    else
      sorted = parts_count.sort_by { |name, count| [-count, name] }
      sorted.each do |part_name, count|
        cost = (@parts[part_name] * count * 100).round / 100.0
        puts "  #{part_name} x#{count} = #{format('%.2f', cost)}"
      end
    end
  end

  def build_tree(name, qty, tree, path)
    # Check if name is already in path (cycle detection)
    if path.include?(name)
      cycle_path = path[path.index(name)..-1] + [name]
      return cycle_path.join(" > ")
    end

    # Check if item exists
    if !@parts[name] && !@assemblies[name]
      if path.empty?
        return nil  # Will be checked before calling
      else
        return "unknown item #{name} in #{path[-1]}"
      end
    end

    # Calculate unit cost
    unit_cost = calculate_unit_cost(name)

    tree_entry = {
      name: name,
      qty: qty,
      unit_cost: unit_cost,
      children: []
    }

    # If it's an assembly, add components
    if @assemblies[name]
      assy = @assemblies[name]
      new_path = path + [name]

      assy[:components].each do |comp|
        comp_qty = qty * comp[:qty]
        cycle = build_tree(comp[:name], comp_qty, tree_entry[:children], new_path)
        return cycle if cycle
      end
    end

    tree << tree_entry
    nil
  end

  def calculate_unit_cost(name)
    if @parts[name]
      @parts[name]
    else
      assy = @assemblies[name]
      cost = assy[:labor]
      assy[:components].each do |comp|
        comp_cost = calculate_unit_cost(comp[:name])
        cost += comp_cost * comp[:qty]
      end
      cost
    end
  end

  def print_tree(tree, indent)
    tree.each do |entry|
      total_cost = entry[:qty] * entry[:unit_cost]
      indent_str = "  " * indent
      puts "#{indent_str}#{entry[:qty]} x #{entry[:name]} = #{format('%.2f', total_cost)}"
      print_tree(entry[:children], indent + 1)
    end
  end

  def collect_parts(tree, parts_count)
    tree.each do |entry|
      if @parts[entry[:name]]
        parts_count[entry[:name]] ||= 0
        parts_count[entry[:name]] += entry[:qty]
      end
      collect_parts(entry[:children], parts_count)
    end
  end

  def error_msg(msg)
    error(msg)
    false
  end

  def error(msg)
    puts "line #{@line_num}: error: #{msg}"
  end
end

bom = BOM.new
bom.run
