class BadLine < StandardError; end
class CannotBuild < StandardError; end

Part = Struct.new(:cost)
Assy = Struct.new(:labor, :comps) # comps: [[name, qty], ...]

NAME = /\A[a-z][a-z0-9_]{0,15}\z/

def money(c) = format("%d.%02d", c / 100, c % 100)

def money!(s)
  m = s.match(/\A(\d+)\.(\d\d)\z/) or raise BadLine, "bad cost"
  m[1].to_i * 100 + m[2].to_i
end

def name!(s) = s.match?(NAME) ? s : raise(BadLine, "bad name")

# Checks the structure below name, depth first in component order.
def check(items, name, path)
  if path.include?(name)
    raise CannotBuild, "cycle #{(path[path.index(name)..] + [name]).join(" > ")}"
  end
  item = items[name]
  raise CannotBuild, path.empty? ? "unknown item #{name}" : "unknown item #{name} in #{path.last}" unless item
  return unless item.is_a?(Assy)
  item.comps.each { |c, _| check(items, c, path + [name]) }
end

def unit_cost(items, name)
  item = items[name]
  return item.cost if item.is_a?(Part)
  costs = item.comps.map { |c, q| (u = unit_cost(items, c)) && q * u }
  costs.include?(nil) ? nil : item.labor + costs.sum
end

def explode(items, name, qty, depth, parts)
  u = unit_cost(items, name)
  puts "#{"  " * depth}#{qty} x #{name} = #{u ? money(qty * u) : "?"}"
  item = items[name]
  if item.is_a?(Part)
    parts[name] += qty
  else
    item.comps.each { |c, q| explode(items, c, qty * q, depth + 1, parts) }
  end
end

items = {}
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    case f[0]
    when "PART"
      raise BadLine, "wrong field count" unless f.size == 3
      name = name!(f[1])
      cost = f[2] == "?" ? nil : money!(f[2])
      raise BadLine, "duplicate #{name}" if items[name]
      items[name] = Part.new(cost)
    when "ASSY"
      raise BadLine, "wrong field count" unless f.size >= 4
      name = name!(f[1])
      labor = money!(f[2])
      comps = f[3..].map do |s|
        m = s.match(/\A([^:]+):(\d+)\z/)
        raise BadLine, "bad component #{s}" unless m && m[1].match?(NAME) && m[2].to_i.between?(1, 999)
        [m[1], m[2].to_i]
      end
      dup = comps.map(&:first).tally.find { |_, n| n > 1 }
      raise BadLine, "repeated component #{dup[0]}" if dup
      raise BadLine, "duplicate #{name}" if items[name]
      items[name] = Assy.new(labor, comps)
    when "BUILD"
      raise BadLine, "wrong field count" unless f.size == 3
      name = name!(f[1])
      raise BadLine, "bad quantity" unless f[2].match?(/\A\d+\z/) && f[2].to_i.between?(1, 1000)
      check(items, name, [])
      parts = Hash.new(0)
      explode(items, name, f[2].to_i, 0, parts)
      puts "parts:"
      parts.sort_by { |n, q| [-q, n] }.each do |n, q|
        puts "  #{n} x#{q} = #{items[n].cost ? money(q * items[n].cost) : "?"}"
      end
      unk = parts.keys.select { |n| items[n].cost.nil? }.sort
      puts "unknown cost: #{unk.join(", ")}" unless unk.empty?
    else
      raise BadLine, "unknown command"
    end
  rescue BadLine => e
    puts "line #{lineno}: error: #{e.message}"
  rescue CannotBuild => e
    puts "line #{lineno}: cannot build: #{e.message}"
  end
end
