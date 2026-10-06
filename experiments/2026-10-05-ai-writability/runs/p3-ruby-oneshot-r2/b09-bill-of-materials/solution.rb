def money(c) = format("%d.%02d", c / 100, c % 100)
def cents(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil
NAME = /\A[a-z][a-z0-9_]{0,15}\z/

defs = {}  # name => [:part, cost] | [:assy, labor, [[name, qty], ...]]
okset = {}
unit = {}

# returns error message or nil
check = nil
check = lambda do |item, parent, path|
  d = defs[item]
  if d.nil?
    return parent ? "unknown item #{item} in #{parent}" : "unknown item #{item}"
  end
  if (i = path.index(item))
    return "cycle " + (path[i..] + [item]).join(" > ")
  end
  return nil if okset[item]
  if d[0] == :assy
    path.push(item)
    d[2].each do |c, _|
      r = check.(c, item, path)
      if r
        path.pop
        return r
      end
    end
    path.pop
  end
  okset[item] = true
  nil
end

ucost = lambda do |item|
  unit[item] ||= begin
    d = defs[item]
    if d[0] == :part
      d[1]
    else
      d[1] + d[2].sum { |c, q| q * ucost.(c) }
    end
  end
end

n = 0
$stdin.each_line do |raw|
  n += 1
  line = raw.strip
  next if line.empty?
  f = line.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "PART"
    if f.size != 3 then err.("wrong field count")
    elsif f[1] !~ NAME then err.("bad name")
    elsif cents(f[2]).nil? then err.("bad cost")
    elsif defs[f[1]] then err.("duplicate #{f[1]}")
    else defs[f[1]] = [:part, cents(f[2])]
    end
  when "ASSY"
    if f.size < 4 then err.("wrong field count")
    elsif f[1] !~ NAME then err.("bad name")
    elsif cents(f[2]).nil? then err.("bad cost")
    else
      comps = []
      bad = f[3..].find do |t|
        if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && $2.to_i.between?(1, 999)
          comps << [$1, $2.to_i]
          false
        else
          true
        end
      end
      if bad then err.("bad component #{bad}")
      elsif (dup = comps.map(&:first).tally.find { |_, v| v > 1 }) then err.("repeated component #{dup[0]}")
      elsif defs[f[1]] then err.("duplicate #{f[1]}")
      else defs[f[1]] = [:assy, cents(f[2]), comps]
      end
    end
  when "BUILD"
    if f.size != 3 then err.("wrong field count")
    elsif f[1] !~ NAME then err.("bad name")
    elsif f[2] !~ /\A\d+\z/ || !f[2].to_i.between?(1, 1000) then err.("bad quantity")
    else
      okset.clear
      r = check.(f[1], nil, [])
      if r
        puts "line #{n}: cannot build: #{r}"
      else
        parts = Hash.new(0)
        walk = nil
        walk = lambda do |item, qty, depth|
          puts "#{'  ' * depth}#{qty} x #{item} = #{money(qty * ucost.(item))}"
          d = defs[item]
          if d[0] == :part
            parts[item] += qty
          else
            d[2].each { |c, q| walk.(c, qty * q, depth + 1) }
          end
        end
        walk.(f[1], f[2].to_i, 0)
        puts "parts:"
        parts.sort_by { |k, v| [-v, k] }.each do |k, v|
          puts "  #{k} x#{v} = #{money(v * defs[k][1])}"
        end
      end
    end
  else
    err.("unknown command")
  end
end
