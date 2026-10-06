def money(c) = format("%d.%02d", c / 100, c % 100)

NAME = /\A[a-z][a-z0-9_]{0,15}\z/
COST = /\A(\d+)\.(\d\d)\z/
items = {}   # name => [:part, cost] | [:assy, labor, [[comp, qty]...]]
out = []

class Stop < StandardError; end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.strip.split(" ")
  next if f.empty?
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "PART"
    (err.("wrong field count"); next) unless f.size == 3
    (err.("bad name"); next) unless f[1] =~ NAME
    (err.("bad cost"); next) unless f[2] =~ COST
    cost = $1.to_i * 100 + $2.to_i
    (err.("duplicate #{f[1]}"); next) if items[f[1]]
    items[f[1]] = [:part, cost]
  when "ASSY"
    (err.("wrong field count"); next) unless f.size >= 4
    (err.("bad name"); next) unless f[1] =~ NAME
    (err.("bad cost"); next) unless f[2] =~ COST
    labor = $1.to_i * 100 + $2.to_i
    comps = []
    bad = nil
    f[3..].each do |t|
      if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && $2.to_i.between?(1, 999)
        comps << [$1, $2.to_i]
      else
        bad = t; break
      end
    end
    (err.("bad component #{bad}"); next) if bad
    seen = {}
    rep = comps.find { |c, _| seen[c] ? true : (seen[c] = true; false) }
    (err.("repeated component #{rep[0]}"); next) if rep
    (err.("duplicate #{f[1]}"); next) if items[f[1]]
    items[f[1]] = [:assy, labor, comps]
  when "BUILD"
    (err.("wrong field count"); next) unless f.size == 3
    (err.("bad name"); next) unless f[1] =~ NAME
    (err.("bad quantity"); next) unless f[2] =~ /\A\d+\z/ && f[2].to_i.between?(1, 1000)
    qty = f[2].to_i
    root = f[1]
    path = []
    ok = {}
    check = lambda do |nm, parent|
      it = items[nm]
      unless it
        raise Stop, (parent ? "unknown item #{nm} in #{parent}" : "unknown item #{nm}")
      end
      if (i = path.index(nm))
        raise Stop, "cycle " + (path[i..] + [nm]).join(" > ")
      end
      next if ok[nm]
      if it[0] == :assy
        path << nm
        it[2].each { |c, _| check.(c, nm) }
        path.pop
      end
      ok[nm] = true
    end
    begin
      check.(root, nil)
    rescue Stop => e
      out << "line #{n}: cannot build: #{e.message}"
      next
    end
    unit = {}
    uc = lambda do |nm|
      unit[nm] ||= begin
        it = items[nm]
        it[0] == :part ? it[1] : it[1] + it[2].sum { |c, q| q * uc.(c) }
      end
    end
    parts = Hash.new(0)
    walk = lambda do |nm, q, depth|
      out << "#{'  ' * depth}#{q} x #{nm} = #{money(q * uc.(nm))}"
      it = items[nm]
      if it[0] == :part
        parts[nm] += q
      else
        it[2].each { |c, cq| walk.(c, q * cq, depth + 1) }
      end
    end
    walk.(root, qty, 0)
    out << "parts:"
    parts.sort_by { |nm, q| [-q, nm] }.each { |nm, q| out << "  #{nm} x#{q} = #{money(q * items[nm][1])}" }
  else
    err.("unknown command")
  end
end
puts out
