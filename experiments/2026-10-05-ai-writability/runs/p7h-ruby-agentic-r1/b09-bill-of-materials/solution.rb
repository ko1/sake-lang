class BOM
  def initialize
    @parts = {}  # name -> cost
    @assemblies = {}  # name -> {labor:, components: [{name:, qty:}]}
    @line_num = 0
  end

  def run(input)
    input.each_line do |line|
      @line_num += 1
      process_line(line)
    end
  end

  private

  def process_line(line)
    line = line.strip
    return if line.empty?

    parts = line.split
    command = parts[0]

    case command
    when 'PART'
      process_part(parts)
    when 'ASSY'
      process_assy(parts)
    when 'BUILD'
      process_build(parts)
    else
      puts "line #{@line_num}: error: unknown command"
    end
  end

  def validate_name(name)
    name =~ /^[a-z][a-z0-9_]{0,15}$/
  end

  def validate_cost(cost)
    cost =~ /^\d+\.\d{2}$/
  end

  def process_part(parts)
    unless parts.length == 3
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    cost = parts[2]

    unless validate_name(name)
      puts "line #{@line_num}: error: bad name"
      return
    end

    unless validate_cost(cost)
      puts "line #{@line_num}: error: bad cost"
      return
    end

    if @parts[name] || @assemblies[name]
      puts "line #{@line_num}: error: duplicate #{name}"
      return
    end

    @parts[name] = cost.to_f
  end

  def process_assy(parts)
    unless parts.length >= 4
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    labor = parts[2]

    unless validate_name(name)
      puts "line #{@line_num}: error: bad name"
      return
    end

    unless validate_cost(labor)
      puts "line #{@line_num}: error: bad cost"
      return
    end

    # Parse components
    components = []
    seen_components = Set.new

    (3...parts.length).each do |i|
      comp_spec = parts[i]

      # Parse COMP:QTY
      if comp_spec.include?(':')
        comp_parts = comp_spec.split(':')
        if comp_parts.length != 2
          puts "line #{@line_num}: error: bad component #{comp_spec}"
          return
        end

        comp_name = comp_parts[0]
        qty_str = comp_parts[1]

        unless validate_name(comp_name)
          puts "line #{@line_num}: error: bad component #{comp_spec}"
          return
        end

        unless qty_str =~ /^\d+$/ && qty_str.to_i >= 1 && qty_str.to_i <= 999
          puts "line #{@line_num}: error: bad component #{comp_spec}"
          return
        end

        if seen_components.include?(comp_name)
          puts "line #{@line_num}: error: repeated component #{comp_name}"
          return
        end

        seen_components.add(comp_name)
        components.push({name: comp_name, qty: qty_str.to_i})
      else
        puts "line #{@line_num}: error: bad component #{comp_spec}"
        return
      end
    end

    if @parts[name] || @assemblies[name]
      puts "line #{@line_num}: error: duplicate #{name}"
      return
    end

    @assemblies[name] = {labor: labor.to_f, components: components}
  end

  def process_build(parts)
    unless parts.length == 3
      puts "line #{@line_num}: error: wrong field count"
      return
    end

    name = parts[1]
    qty_str = parts[2]

    unless validate_name(name)
      puts "line #{@line_num}: error: bad name"
      return
    end

    unless qty_str =~ /^\d+$/ && qty_str.to_i >= 1 && qty_str.to_i <= 1000
      puts "line #{@line_num}: error: bad quantity"
      return
    end

    qty = qty_str.to_i

    # Check if item exists
    unless @parts[name] || @assemblies[name]
      puts "line #{@line_num}: cannot build: unknown item #{name}"
      return
    end

    # Build the BOM
    @parts_list = {}  # name -> qty
    path = []
    error = build_tree(name, qty, path)

    if error
      puts "line #{@line_num}: cannot build: #{error}"
      return
    end

    # Print the tree
    print_tree(name, qty, 0, {})

    # Print parts summary
    puts "parts:"
    if @parts_list.empty?
      # Handle case where there are no purchased parts
    else
      sorted_parts = @parts_list.sort_by { |n, q| [-q, n] }
      sorted_parts.each do |part_name, total_qty|
        cost = @parts[part_name]
        total_cost = total_qty * cost
        puts "  #{part_name} x#{total_qty} = #{format('%.2f', total_cost)}"
      end
    end
  end

  def build_tree(name, qty, path)
    # Check if item is defined
    if !@parts[name] && !@assemblies[name]
      if path.empty?
        return "unknown item #{name}"
      else
        return "unknown item #{name} in #{path[-1]}"
      end
    end

    # Check for cycle
    if path.include?(name)
      cycle_path = path[path.index(name)..-1] + [name]
      return "cycle #{cycle_path.join(' > ')}"
    end

    # If it's a part, just add to the list
    if @parts[name]
      @parts_list[name] ||= 0
      @parts_list[name] += qty
      return nil
    end

    # If it's an assembly, recurse on components
    assy = @assemblies[name]
    new_path = path + [name]

    assy[:components].each do |comp|
      error = build_tree(comp[:name], qty * comp[:qty], new_path)
      return error if error
    end

    nil
  end

  def print_tree(name, qty, depth, cache)
    indent = '  ' * depth

    # Get unit cost
    if @parts[name]
      unit_cost = @parts[name]
      cost = qty * unit_cost
    else
      assy = @assemblies[name]
      unit_cost = assy[:labor]
      assy[:components].each do |comp|
        comp_unit_cost = @parts[comp[:name]] || @assemblies[comp[:name]][:labor]
        comp_unit_cost = calculate_unit_cost(comp[:name]) if @assemblies[comp[:name]]
        unit_cost += comp[:qty] * comp_unit_cost
      end
      cost = qty * unit_cost
    end

    puts "#{indent}#{qty} x #{name} = #{format('%.2f', cost)}"

    # Print components
    if @assemblies[name]
      assy = @assemblies[name]
      assy[:components].each do |comp|
        print_tree(comp[:name], qty * comp[:qty], depth + 1, cache)
      end
    end
  end

  def calculate_unit_cost(name)
    if @parts[name]
      return @parts[name]
    else
      assy = @assemblies[name]
      cost = assy[:labor]
      assy[:components].each do |comp|
        comp_cost = calculate_unit_cost(comp[:name])
        cost += comp[:qty] * comp_cost
      end
      return cost
    end
  end
end

bom = BOM.new
bom.run(STDIN.read)
