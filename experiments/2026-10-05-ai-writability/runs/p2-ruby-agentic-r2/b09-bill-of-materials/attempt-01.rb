NAME = /\A[a-z][a-z0-9_]{0,15}\z/
MONEY = /\A(\d+)\.(\d\d)\z/

def money(c) = format("%d.%02d", c / 100, c % 100)

class Stop < StandardError; end

defs = {}

$stdin.each_line.with_index(1) do |raw, n|
  next if raw.strip.empty?
  f = raw.strip.split(/ +/)
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "PART"
    if f.size != 3 then err.("wrong field count"); next end
    unless f[1] =~ NAME then err.("bad name"); next end
    unless f[2] =~ MONEY then err.("bad cost"); next end
    cost = $1.to_i * 100 + $2.to_i
    if defs.key?(f[1]) then err.("duplicate #{f[1]}"); next end
    defs[f[1]] = { part: true, cost: cost }
  when "ASSY"
    if f.size < 4 then err.("wrong field count"); next end
    unless f[1] =~ NAME then err.("bad name"); next end
    unless f[2] =~ MONEY then err.("bad cost"); next end
    labor = $1.to_i * 100 + $2.to_i
    comps = []
    bad = nil
    f[3..].each do |t|
      if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && (1..999).cover?($2.to_i)
        comps << [$1, $2.to_i]
      else
        bad = t
        break
      end
    end
    if bad then err.("bad component #{bad}"); next end
    names = comps.map(&:first)
    if (dup = names.find { |x| names.count(x) > 1 })
      err.("repeated component #{dup}"); next
    end
    if defs.key?(f[1]) then err.("duplicate #{f[1]}"); next end
    defs[f[1]] = { part: false, labor: labor, comps: comps }
  when "BUILD"
    if f.size != 3 then err.("wrong field count"); next end
    unless f[1] =~ NAME then err.("bad name"); next end
    unless f[2] =~ /\A\d+\z/ && (1..1000).cover?(f[2].to_i) then err.("bad quantity"); next end
    qty = f[2].to_i
    ok = {}
    path = []
    check = nil
    check = lambda do |x, parent|
      unless defs.key?(x)
        raise Stop, (parent ? "unknown item #{x} in #{parent}" : "unknown item #{x}")
      end
      if (i = path.index(x))
        raise Stop, "cycle #{(path[i..] + [x]).join(' > ')}"
      end
      return if ok[x]
      unless defs[x][:part]
        path.push(x)
        defs[x][:comps].each { |c, _| check.(c, x) }
        path.pop
      end
      ok[x] = true
    end
    begin
      check.(f[1], nil)
    rescue Stop => e
      puts "line #{n}: cannot build: #{e.message}"
      next
    end
    unit = {}
    uc = nil
    uc = lambda do |x|
      unit[x] ||= defs[x][:part] ? defs[x][:cost] : defs[x][:labor] + defs[x][:comps].sum { |c, q| q * uc.(c) }
    end
    totals = Hash.new(0)
    walk = nil
    walk = lambda do |x, q, depth|
      puts "#{'  ' * depth}#{q} x #{x} = #{money(q * uc.(x))}"
      if defs[x][:part]
        totals[x] += q
      else
        defs[x][:comps].each { |c, cq| walk.(c, q * cq, depth + 1) }
      end
    end
    walk.(f[1], qty, 0)
    puts "parts:"
    totals.sort_by { |name, q| [-q, name] }.each do |name, q|
      puts "  #{name} x#{q} = #{money(q * uc.(name))}"
    end
  else
    err.("unknown command")
  end
end
