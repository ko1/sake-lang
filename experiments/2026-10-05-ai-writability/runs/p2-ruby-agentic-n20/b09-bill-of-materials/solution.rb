def money(c) = format("%d.%02d", c / 100, c % 100)
def cents(s) = s.delete(".").to_i

NAME = /\A[a-z][a-z0-9_]{0,15}\z/
MONEY = /\A\d+\.\d\d\z/

items = {} # name => [:part, cost] | [:assy, labor, [[name, qty], ...]]

# returns error string or nil; ok = validated set
walk = lambda do |name, parent, path, ok|
  unless items.key?(name)
    return parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}"
  end
  return nil if ok[name]
  if (i = path.index(name))
    return "cycle " + (path[i..] + [name]).join(" > ")
  end
  if items[name][0] == :assy
    path.push(name)
    items[name][2].each do |c, _|
      r = walk.call(c, name, path, ok)
      return r if r
    end
    path.pop
  end
  ok[name] = true
  nil
end

unit = {}
unit_cost = lambda do |n|
  unit[n] ||= items[n][0] == :part ? items[n][1] : items[n][1] + items[n][2].sum { |c, q| q * unit_cost.call(c) }
end

$stdin.each_line.with_index(1) do |line, no|
  f = line.chomp.split(/ +/).reject(&:empty?)
  next if f.empty?
  cmd = f[0]
  ok = %w[PART ASSY BUILD].include?(cmd)
  unless ok
    puts "line #{no}: error: unknown command"
    next
  end
  cnt_ok = case cmd when "PART", "BUILD" then f.size == 3 else f.size >= 4 end
  unless cnt_ok
    puts "line #{no}: error: wrong field count"
    next
  end
  case cmd
  when "PART", "ASSY"
    err = nil
    comps = []
    if f[1] !~ NAME then err = "bad name"
    elsif f[2] !~ MONEY then err = "bad cost"
    elsif cmd == "ASSY"
      f[3..].each do |t|
        if t =~ /\A(#{NAME.source[2..-3]}):(\d+)\z/ && (1..999).cover?($2.to_i)
          comps << [$1, $2.to_i]
        else
          err = "bad component #{t}"
          break
        end
      end
      err ||= (d = comps.map(&:first).tally.find { |_, v| v > 1 }) && "repeated component #{d[0]}"
    end
    err ||= "duplicate #{f[1]}" if items.key?(f[1])
    if err
      puts "line #{no}: error: #{err}"
      next
    end
    items[f[1]] = cmd == "PART" ? [:part, cents(f[2])] : [:assy, cents(f[2]), comps]
    unit.clear
  when "BUILD"
    name = f[1]
    if name !~ NAME
      puts "line #{no}: error: bad name"
      next
    end
    if f[2] !~ /\A\d+\z/ || !(1..1000).cover?(f[2].to_i)
      puts "line #{no}: error: bad quantity"
      next
    end
    r = walk.call(name, nil, [], {})
    if r
      puts "line #{no}: cannot build: #{r}"
      next
    end
    totals = Hash.new(0)
    out = lambda do |n, q, depth|
      puts "#{'  ' * depth}#{q} x #{n} = #{money(q * unit_cost.call(n))}"
      if items[n][0] == :part
        totals[n] += q
      else
        items[n][2].each { |c, cq| out.call(c, q * cq, depth + 1) }
      end
    end
    out.call(name, f[2].to_i, 0)
    puts "parts:"
    totals.sort_by { |n, q| [-q, n.b] }.each do |n, q|
      puts "  #{n} x#{q} = #{money(q * items[n][1])}"
    end
  end
end
