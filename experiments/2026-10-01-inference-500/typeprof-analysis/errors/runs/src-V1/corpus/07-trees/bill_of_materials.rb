class CycleError < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

class UnknownPart < StandardError
  attr_reader :part

  def initialize(message, part)
    super(message)
    @part = part
  end
end

class Catalog
  attr_reader :assemblies, :prices, :memo

  def self.parse(text)
    cat = new
    text.each_line do |line|
      line = line.strip
      next if line.empty?
      if line.include?("=")
        name, rest = line.split("=")
        cat.assemblies[name.strip] = rest.split("+").map do |item|
          m = item.strip.match(/\A(\d+)\s*x\s*(.+)\z/)
          raise ArgumentError, "bad item #{item.inspect}" if m.nil?
          [m[2].strip, m[1].to_i]
        end
      else
        name, price = line.split("$")
        cat.prices[name.strip] = price.to_f
      end
    end
    cat
  end

  def initialize
    @assemblies = {}
    @prices = {}
    @memo = {}
  end

  def raw?(part) = prices.key?(part)

  def check(part, path)
    raise CycleError.new("cycle: #{path.join(" > ")} > #{part}", path.join(">")) if path.include?(part)
    return if raw?(part)
    kids = assemblies[part]
    raise UnknownPart.new("#{part} is neither a raw part nor an assembly (in #{path.last})", part) if kids.nil?
    path.push(part)
    kids.each { |child, _qty| check(child, path) }
    path.pop
  end

  def cost(part)
    return prices[part] if raw?(part)
    memo[part] ||= assemblies[part].sum { |child, qty| qty * cost(child) }
  end

  def explode(part, qty, depth, out)
    out << [depth, part, qty]
    return out if raw?(part)
    assemblies[part].each { |child, n| explode(child, qty * n, depth + 1, out) }
    out
  end

  def requirements(part, qty, need)
    if raw?(part)
      need[part] += qty
    else
      assemblies[part].each { |child, n| requirements(child, qty * n, need) }
    end
    need
  end

  def where_used(part)
    assemblies.select { |_name, parts| parts.any? { |child, _n| child == part } }.keys.sort
  end
end

catalog_text = <<~BOM
  bicycle = 1 x frame set + 2 x wheel + 1 x drivetrain + 1 x saddle
  frame set = 1 x frame + 1 x fork + 1 x headset
  wheel = 1 x rim + 32 x spoke + 1 x hub + 1 x tire + 1 x tube
  drivetrain = 1 x crankset + 1 x chain + 2 x pedal + 1 x cassette
  crankset = 2 x crank arm + 1 x chainring + 1 x bottom bracket
  frame $ 420.00
  fork $ 150.00
  headset $ 35.50
  rim $ 48.00
  spoke $ 0.65
  hub $ 62.00
  tire $ 29.90
  tube $ 6.50
  chain $ 24.00
  pedal $ 18.75
  cassette $ 55.00
  crank arm $ 31.00
  chainring $ 27.00
  bottom bracket $ 22.00
  saddle $ 44.00
BOM
cat = Catalog.parse(catalog_text)
cat.check("bicycle", [])
puts "-- exploded bill for 1 bicycle --"
cat.explode("bicycle", 1, 0, []).each do |depth, part, qty|
  puts format("%-28s %4d  %9.2f", "#{"  " * depth}#{part}", qty, cat.cost(part) * qty)
end
puts format("unit cost: %.2f", cat.cost("bicycle"))

puts "-- raw parts for an order of 25 bicycles --"
need = cat.requirements("bicycle", 25, Hash.new(0))
rows = need.sort_by { |part, qty| [-(qty * cat.cost(part)), part] }
rows.take(5).each do |part, qty|
  puts format("  %-15s %5d  %10.2f", part, qty, qty * cat.cost(part))
end
puts "  ... #{rows.size - 5} more raw parts, #{need.values.sum} pieces in total"
puts "where is 'pedal' used: #{cat.where_used("pedal").join(", ")}"
puts "where is 'spoke' used: #{cat.where_used("spoke").join(", ")}"

broken = ["kit = 1 x box + 2 x widget\nwidget = 1 x gear + 1 x kit\ngear $ 1.0\nbox $ 2.0\n",
          "kit = 1 x box + 3 x gizmo\nbox $ 2.0\n",
          "kit = one x box\nbox $ 2.0\n"]
broken.each do |text|
  c = Catalog.parse(text)
  c.check("kit", [])
  puts "ok"
rescue CycleError => e
  puts "rejected: #{e.message}"
rescue UnknownPart => e
  puts "rejected: #{e.message} [part #{e.part}]"
rescue ArgumentError => e
  puts "rejected: #{e.message}"
end
