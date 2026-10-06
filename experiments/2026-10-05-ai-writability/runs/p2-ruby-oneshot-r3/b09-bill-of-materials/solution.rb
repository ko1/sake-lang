NAME_RE = /\A[a-z][a-z0-9_]{0,15}\z/
COST_RE = /\A(\d+)\.(\d\d)\z/
def money(c) = format("%d.%02d", c / 100, c % 100)
def cents(s) = (s =~ COST_RE ? $1.to_i * 100 + $2.to_i : nil)

defs = {}  # name => [:part, cost] | [:assy, labor, [[comp, qty], ...]]
out = []
ok = {}
$err = nil

check = lambda do |name, path, parent|
  d = defs[name]
  if d.nil?
    $err = parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}"
    return false
  end
  if (i = path.index(name))
    $err = "cycle " + (path[i..] + [name]).join(" > ")
    return false
  end
  return true if ok[name]
  if d[0] == :assy
    path.push(name)
    d[2].each do |(c, _)|
      unless check.call(c, path, name)
        path.pop
        return false
      end
    end
    path.pop
  end
  ok[name] = true
  true
end

unit_memo = {}
unit = lambda do |name|
  unit_memo[name] ||= begin
    d = defs[name]
    d[0] == :part ? d[1] : d[1] + d[2].sum { |(c, q)| q * unit.call(c) }
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.strip
  next if line.empty?
  f = line.split
  case f[0]
  when "PART"
    if f.size != 3
      out << "line #{n}: error: wrong field count"
    elsif f[1] !~ NAME_RE
      out << "line #{n}: error: bad name"
    elsif (c = cents(f[2])).nil?
      out << "line #{n}: error: bad cost"
    elsif defs.key?(f[1])
      out << "line #{n}: error: duplicate #{f[1]}"
    else
      defs[f[1]] = [:part, c]
    end
  when "ASSY"
    if f.size < 4
      out << "line #{n}: error: wrong field count"
    elsif f[1] !~ NAME_RE
      out << "line #{n}: error: bad name"
    elsif (c = cents(f[2])).nil?
      out << "line #{n}: error: bad cost"
    else
      comps = []
      bad = nil
      f[3..].each do |t|
        if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && $2.to_i.between?(1, 999)
          comps << [$1, $2.to_i]
        else
          bad = t
          break
        end
      end
      if bad
        out << "line #{n}: error: bad component #{bad}"
      elsif (dup = comps.map(&:first).find { |x| comps.count { |(y, _)| y == x } > 1 })
        out << "line #{n}: error: repeated component #{dup}"
      elsif defs.key?(f[1])
        out << "line #{n}: error: duplicate #{f[1]}"
      else
        defs[f[1]] = [:assy, c, comps]
      end
    end
  when "BUILD"
    if f.size != 3
      out << "line #{n}: error: wrong field count"
    elsif f[1] !~ NAME_RE
      out << "line #{n}: error: bad name"
    elsif f[2] !~ /\A\d+\z/ || !f[2].to_i.between?(1, 1000)
      out << "line #{n}: error: bad quantity"
    else
      name = f[1]
      qty = f[2].to_i
      ok = {}
      if !check.call(name, [], nil)
        out << "line #{n}: cannot build: #{$err}"
      else
        parts = Hash.new(0)
        walk = lambda do |nm, q, depth|
          out << "#{'  ' * depth}#{q} x #{nm} = #{money(q * unit.call(nm))}"
          d = defs[nm]
          if d[0] == :part
            parts[nm] += q
          else
            d[2].each { |(c, cq)| walk.call(c, q * cq, depth + 1) }
          end
        end
        walk.call(name, qty, 0)
        out << "parts:"
        parts.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
          out << "  #{nm} x#{q} = #{money(q * defs[nm][1])}"
        end
      end
    end
  else
    out << "line #{n}: error: unknown command"
  end
end
puts out
