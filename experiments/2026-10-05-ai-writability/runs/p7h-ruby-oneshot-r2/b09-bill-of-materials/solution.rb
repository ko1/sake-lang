#!/usr/bin/env ruby

def valid_name?(s)
  s =~ /^[a-z][a-z0-9_]{0,15}$/
end

def valid_cost?(s)
  s =~ /^\d+\.\d{2}$/
end

parts = {}      # name -> cost
assemblies = {} # name -> {labor, components: [{name, qty}]}

def build_tree(item, qty, definitions, path, parts_total)
  if path.include?(item)
    cycle_path = path[path.index(item)..-1] + [item]
    cycle_str = cycle_path.join(' > ')
    return nil, "cycle #{cycle_str}"
  end

  if !definitions[item] && !parts[item]
    if path.empty?
      return nil, "unknown item #{item}"
    else
      return nil, "unknown item #{item} in #{path[-1]}"
    end
  end

  cost = 0
  tree = []

  if parts[definitions[item][:type] == :part ? item : item]
    if definitions[item][:type] == :part
      cost = definitions[item][:cost] * qty
      parts_total[item] = (parts_total[item] || 0) + qty
    end
  else
    assy = definitions[item]
    cost = assy[:labor] * qty

    new_path = path + [item]
    assy[:components].each do |comp_name, comp_qty|
      total_qty = comp_qty * qty
      comp_cost, comp_tree, err = build_tree(comp_name, total_qty, definitions, new_path, parts_total)
      return nil, nil, err if err
      cost += comp_cost
      tree << [comp_name, total_qty, comp_cost, comp_tree]
    end
  end

  return cost, tree, nil
end

def calculate_cost(item, qty, definitions, parts_table)
  if definitions[item][:type] == :part
    return definitions[item][:cost] * qty
  else
    assy = definitions[item]
    cost = assy[:labor] * qty
    assy[:components].each do |comp_name, comp_qty|
      cost += calculate_cost(comp_name, comp_qty * qty, definitions, parts_table)
    end
    return cost
  end
end

def print_tree(item, qty, definitions, parts_table, indent = 0)
  cost = calculate_cost(item, qty, definitions, parts_table)
  puts "#{'  ' * indent}#{qty} x #{item} = #{format('%.2f', cost)}"

  if definitions[item][:type] == :assy
    definitions[item][:components].each do |comp_name, comp_qty|
      print_tree(comp_name, comp_qty * qty, definitions, parts_table, indent + 1)
    end
  end
end

definitions = {} # name -> {type, ...}

$stdin.each_line.with_index do |line, idx|
  line_num = idx + 1
  line = line.chomp
  next if line.empty?

  fields = line.split
  next if fields.empty?

  cmd = fields[0]
  case cmd
  when "PART"
    if fields.size != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    cost_str = fields[2]

    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end
    if !valid_cost?(cost_str)
      puts "line #{line_num}: error: bad cost"
      next
    end
    if definitions[name]
      puts "line #{line_num}: error: duplicate #{name}"
      next
    end

    cost = cost_str.to_f
    definitions[name] = {type: :part, cost: cost}

  when "ASSY"
    if fields.size < 4
      puts "line #{line_num}: error: wrong field count"
      next
    end

    name = fields[1]
    labor_str = fields[2]

    if !valid_name?(name)
      puts "line #{line_num}: error: bad name"
      next
    end
    if !valid_cost?(labor_str)
      puts "line #{line_num}: error: bad cost"
      next
    end
    if definitions[name]
      puts "line #{line_num}: error: duplicate #{name}"
      next
    end

    labor = labor_str.to_f
    components = []
    seen_comps = Set.new

    fields[3..-1].each do |comp_field|
      if !comp_field.include?(':')
        puts "line #{line_num}: error: bad component #{comp_field}"
        exit
      end

      parts = comp_field.split(':')
      if parts.size != 2
        puts "line #{line_num}: error: bad component #{comp_field}"
        exit
      end

      comp_name = parts[0]
      comp_qty_str = parts[1]

      if !valid_name?(comp_name)
        puts "line #{line_num}: error: bad component #{comp_field}"
        exit
      end
      if !comp_qty_str.match?(/^\d+$/) || comp_qty_str.to_i < 1 || comp_qty_str.to_i > 999
        puts "line #{line_num}: error: bad component #{comp_field}"
        exit
      end

      if seen_comps.include?(comp_name)
        puts "line #{line_num}: error: repeated component #{comp_name}"
        exit
      end

      comp_qty = comp_qty_str.to_i
      components << [comp_name, comp_qty]
      seen_comps << comp_name
    end

    definitions[name] = {type: :assy, labor: labor, components: components}

  when "BUILD"
    if fields.size != 3
      puts "line #{line_num}: error: wrong field count"
      next
    end

    item = fields[1]
    qty_str = fields[2]

    if !valid_name?(item)
      puts "line #{line_num}: error: bad name"
      next
    end
    if !qty_str.match?(/^\d+$/) || qty_str.to_i < 1 || qty_str.to_i > 1000
      puts "line #{line_num}: error: bad quantity"
      next
    end

    qty = qty_str.to_i

    if !definitions[item]
      puts "line #{line_num}: cannot build: unknown item #{item}"
      next
    end

    # Check for cycles and build tree
    def check_cycles(item, definitions, path)
      if path.include?(item)
        cycle_path = path[path.index(item)..-1] + [item]
        return cycle_path.join(' > ')
      end

      if definitions[item][:type] == :assy
        new_path = path + [item]
        definitions[item][:components].each do |comp_name, _|
          err = check_cycles(comp_name, definitions, new_path)
          return err if err
        end
      end

      nil
    end

    cycle_err = check_cycles(item, definitions, [])
    if cycle_err
      puts "line #{line_num}: cannot build: cycle #{cycle_err}"
      next
    end

    # Print tree
    print_tree(item, qty, definitions, definitions)

    # Calculate parts summary
    parts_summary = {}
    def collect_parts(item, qty, definitions, parts_summary)
      if definitions[item][:type] == :part
        parts_summary[item] = (parts_summary[item] || 0) + qty
      else
        definitions[item][:components].each do |comp_name, comp_qty|
          collect_parts(comp_name, comp_qty * qty, definitions, parts_summary)
        end
      end
    end

    collect_parts(item, qty, definitions, parts_summary)

    puts "parts:"
    if parts_summary.empty?
      # Should not happen in valid builds
    else
      parts_summary.sort_by { |name, total_qty| [-total_qty, name] }.each do |name, total_qty|
        part_cost = definitions[name][:cost]
        total_cost = part_cost * total_qty
        puts "  #{name} x#{total_qty} = #{format('%.2f', total_cost)}"
      end
    end

  else
    puts "line #{line_num}: error: unknown command"
  end
end
