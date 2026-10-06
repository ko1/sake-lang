def money(c)
  format("%d.%02d", c / 100, c % 100)
end

NAME = /\A[a-z][a-z0-9_]{0,15}\z/
MONEY = /\A\d+\.\d\d\z/

items = {}  # name => {kind: :part, cost:} | {kind: :assy, labor:, comps: [[name, qty]]}

class Stop < StandardError; end

def verify(name, parent, items, path, done)
  if path.include?(name)
    i = path.index(name)
    raise Stop, "cycle #{(path[i..] + [name]).join(" > ")}"
  end
  it = items[name]
  if it.nil?
    raise Stop, parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}"
  end
  return if done[name] || it[:kind] == :part
  path.push(name)
  it[:comps].each { |c, _| verify(c, name, items, path, done) }
  path.pop
  done[name] = true
end

def unit(name, items, memo)
  memo[name] ||= begin
    it = items[name]
    if it[:kind] == :part
      it[:cost]
    else
      it[:labor] + it[:comps].sum { |c, q| q * unit(c, items, memo) }
    end
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.chomp.split(" ")
  next if f.empty?
  e = lambda { |m| puts "line #{n}: error: #{m}" }
  cmd = f[0]
  unless %w[PART ASSY BUILD].include?(cmd)
    e.call("unknown command"); next
  end
  ok = case cmd
       when "PART", "BUILD" then f.size == 3
       else f.size >= 4
       end
  unless ok
    e.call("wrong field count"); next
  end
  name = f[1]
  case cmd
  when "PART"
    if name !~ NAME then e.call("bad name"); next end
    if f[2] !~ MONEY then e.call("bad cost"); next end
    if items.key?(name) then e.call("duplicate #{name}"); next end
    items[name] = {kind: :part, cost: f[2].delete(".").to_i}
  when "ASSY"
    if name !~ NAME then e.call("bad name"); next end
    if f[2] !~ MONEY then e.call("bad cost"); next end
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
    if bad then e.call("bad component #{bad}"); next end
    dup = comps.map(&:first).tally.find { |_, c| c > 1 }
    if dup
      # report the first name whose repeat occurs earliest in the list
      seen = {}
      rep = comps.map(&:first).find { |c| seen[c] ? true : (seen[c] = true; false) }
      e.call("repeated component #{rep}"); next
    end
    if items.key?(name) then e.call("duplicate #{name}"); next end
    items[name] = {kind: :assy, labor: f[2].delete(".").to_i, comps: comps}
  when "BUILD"
    if name !~ NAME then e.call("bad name"); next end
    if f[2] !~ /\A\d+\z/ || !(1..1000).cover?(f[2].to_i) then e.call("bad quantity"); next end
    begin
      verify(name, nil, items, [], {})
    rescue Stop => ex
      puts "line #{n}: cannot build: #{ex.message}"
      next
    end
    memo = {}
    totals = Hash.new(0)
    walk = lambda do |nm, q, depth|
      u = unit(nm, items, memo)
      puts "#{"  " * depth}#{q} x #{nm} = #{money(q * u)}"
      it = items[nm]
      if it[:kind] == :part
        totals[nm] += q
      else
        it[:comps].each { |c, cq| walk.call(c, q * cq, depth + 1) }
      end
    end
    walk.call(name, f[2].to_i, 0)
    puts "parts:"
    totals.sort_by { |k, v| [-v, k.b] }.each do |k, v|
      puts "  #{k} x#{v} = #{money(v * items[k][:cost])}"
    end
  end
end
