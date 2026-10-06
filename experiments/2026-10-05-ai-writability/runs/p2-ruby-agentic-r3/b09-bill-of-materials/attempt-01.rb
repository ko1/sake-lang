NAME_RE = /\A[a-z][a-z0-9_]{0,15}\z/
COST_RE = /\A(\d+)\.(\d\d)\z/
def money(c) = format("%d.%02d", c / 100, c % 100)

defs = {}   # name => [:part, cost] | [:assy, labor, [[comp, qty]...]]
out = []
unit = {}

unit_cost = lambda do |nm|
  unit[nm] ||= begin
    d = defs[nm]
    d[0] == :part ? d[1] : d[1] + d[2].sum { |c, q| q * unit_cost.(c) }
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  line = raw.chomp
  next if line.strip.empty?
  f = line.split(/ +/).reject(&:empty?)
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "PART"
    (err.("wrong field count"); next) if f.size != 3
    (err.("bad name"); next) unless f[1] =~ NAME_RE
    (err.("bad cost"); next) unless f[2] =~ COST_RE
    c = $1.to_i * 100 + $2.to_i
    (err.("duplicate #{f[1]}"); next) if defs[f[1]]
    defs[f[1]] = [:part, c]
  when "ASSY"
    (err.("wrong field count"); next) if f.size < 4
    (err.("bad name"); next) unless f[1] =~ NAME_RE
    (err.("bad cost"); next) unless f[2] =~ COST_RE
    labor = $1.to_i * 100 + $2.to_i
    comps = []
    bad = nil
    f[3..].each do |t|
      if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && (1..999).cover?($2.to_i)
        comps << [$1, $2.to_i]
      else
        bad = t; break
      end
    end
    (err.("bad component #{bad}"); next) if bad
    names = comps.map(&:first)
    dup = names.find { |x| names.count(x) > 1 }
    (err.("repeated component #{dup}"); next) if dup
    (err.("duplicate #{f[1]}"); next) if defs[f[1]]
    defs[f[1]] = [:assy, labor, comps]
  when "BUILD"
    (err.("wrong field count"); next) if f.size != 3
    (err.("bad name"); next) unless f[1] =~ NAME_RE
    (err.("bad quantity"); next) unless f[2] =~ /\A\d+\z/ && (1..1000).cover?(f[2].to_i)
    qty = f[2].to_i
    # validate
    problem = nil
    ok = {}
    path = []
    walk = nil
    walk = lambda do |nm, parent|
      if (i = path.index(nm))
        problem = "cycle #{(path[i..] + [nm]).join(' > ')}"
        return false
      end
      unless defs[nm]
        problem = parent ? "unknown item #{nm} in #{parent}" : "unknown item #{nm}"
        return false
      end
      return true if ok[nm]
      if defs[nm][0] == :assy
        path.push(nm)
        defs[nm][2].each { |c, _| return false unless walk.(c, nm) }
        path.pop
      end
      ok[nm] = true
    end
    unless walk.(f[1], nil)
      out << "line #{n}: cannot build: #{problem}"
      next
    end
    parts = Hash.new(0)
    emit = nil
    emit = lambda do |nm, q, depth|
      out << "#{'  ' * depth}#{q} x #{nm} = #{money(q * unit_cost.(nm))}"
      d = defs[nm]
      if d[0] == :part
        parts[nm] += q
      else
        d[2].each { |c, cq| emit.(c, q * cq, depth + 1) }
      end
    end
    emit.(f[1], qty, 0)
    out << "parts:"
    parts.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
      out << "  #{nm} x#{q} = #{money(q * defs[nm][1])}"
    end
  else
    err.("unknown command")
  end
end
puts out
