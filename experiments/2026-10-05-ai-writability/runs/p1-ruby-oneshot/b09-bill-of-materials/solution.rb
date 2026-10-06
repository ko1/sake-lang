def money(c) = format("%d.%02d", c / 100, c % 100)

NAME_RE = /\A[a-z][a-z0-9_]{0,15}\z/
COST_RE = /\A(\d+)\.(\d\d)\z/
COMP_RE = /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/

defs = {}  # name => [:part, cost] | [:assy, labor, [[comp, qty], ...]]

# Returns a problem string for the first problem met depth first, or nil.
def check(defs, name, path, parent, ok)
  d = defs[name]
  return(parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}") unless d
  if (i = path.index(name))
    return "cycle " + (path[i..] + [name]).join(" > ")
  end
  return nil if ok[name]
  if d[0] == :assy
    path.push(name)
    d[2].each do |c, _|
      r = check(defs, c, path, name, ok)
      if r
        path.pop
        return r
      end
    end
    path.pop
  end
  ok[name] = true
  nil
end

def unit(defs, name, memo)
  memo[name] ||= begin
    d = defs[name]
    d[0] == :part ? d[1] : d[1] + d[2].sum { |c, q| q * unit(defs, c, memo) }
  end
end

def walk(defs, name, qty, depth, memo, parts)
  u = unit(defs, name, memo)
  puts "#{'  ' * depth}#{qty} x #{name} = #{money(qty * u)}"
  d = defs[name]
  if d[0] == :part
    parts[name] += qty
  else
    d[2].each { |c, q| walk(defs, c, qty * q, depth + 1, memo, parts) }
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  cmd = f[0]
  err = nil
  case cmd
  when "PART"
    if f.size != 3 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !f[2].match?(COST_RE) then err = "bad cost"
    elsif defs.key?(f[1]) then err = "duplicate #{f[1]}"
    else
      m = COST_RE.match(f[2])
      defs[f[1]] = [:part, m[1].to_i * 100 + m[2].to_i]
    end
  when "ASSY"
    if f.size < 4 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !f[2].match?(COST_RE) then err = "bad cost"
    else
      comps = []
      f[3..].each do |t|
        m = COMP_RE.match(t)
        if m && (1..999).cover?(m[2].to_i)
          comps << [m[1], m[2].to_i]
        else
          err = "bad component #{t}"
          break
        end
      end
      if err.nil?
        names = comps.map(&:first)
        if (dup = names.find { |x| names.count(x) > 1 }) then err = "repeated component #{dup}"
        elsif defs.key?(f[1]) then err = "duplicate #{f[1]}"
        else
          m = COST_RE.match(f[2])
          defs[f[1]] = [:assy, m[1].to_i * 100 + m[2].to_i, comps]
        end
      end
    end
  when "BUILD"
    if f.size != 3 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !(f[2].match?(/\A\d+\z/) && (1..1000).cover?(f[2].to_i)) then err = "bad quantity"
    else
      r = check(defs, f[1], [], nil, {})
      if r
        puts "line #{n}: cannot build: #{r}"
      else
        memo = {}
        parts = Hash.new(0)
        walk(defs, f[1], f[2].to_i, 0, memo, parts)
        puts "parts:"
        parts.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
          puts "  #{nm} x#{q} = #{money(q * defs[nm][1])}"
        end
      end
    end
  else
    err = "unknown command"
  end
  puts "line #{n}: error: #{err}" if err
end
