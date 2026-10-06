def money(c) = format("%d.%02d", c / 100, c % 100)
NAME = /\A[a-z][a-z0-9_]{0,15}\z/
COST = /\A(\d+)\.(\d\d)\z/
def cost(s) = (s =~ COST) ? $1.to_i * 100 + $2.to_i : nil
items = {}   # name => [:part, cost] | [:assy, labor, [[comp, qty]...]]
unit = {}
$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = ->(m) { puts "line #{n}: error: #{m}" }
  case f[0]
  when "PART", "ASSY", "BUILD"
    ok = case f[0] when "PART" then f.size == 3 when "ASSY" then f.size >= 4 else f.size == 3 end
    (err.("wrong field count"); next) unless ok
    (err.("bad name"); next) unless f[1] =~ NAME
    case f[0]
    when "PART"
      c = cost(f[2]); (err.("bad cost"); next) unless c
      (err.("duplicate #{f[1]}"); next) if items.key?(f[1])
      items[f[1]] = [:part, c]
    when "ASSY"
      c = cost(f[2]); (err.("bad cost"); next) unless c
      comps = []
      bad = nil
      f[3..].each do |t|
        if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d{1,3})\z/ && $2.to_i.between?(1, 999)
          comps << [$1, $2.to_i]
        else
          bad = t; break
        end
      end
      (err.("bad component #{bad}"); next) if bad
      names = comps.map(&:first)
      rep = names.find { |x| names.count(x) > 1 }
      (err.("repeated component #{rep}"); next) if rep
      (err.("duplicate #{f[1]}"); next) if items.key?(f[1])
      items[f[1]] = [:assy, c, comps]
    else
      (err.("bad quantity"); next) unless f[2] =~ /\A\d+\z/ && f[2].to_i.between?(1, 1000)
      qty = f[2].to_i
      ok = {}; path = []
      problem = nil
      walk = lambda do |nm, parent|
        return true if ok[nm]
        if path.include?(nm)
          problem = "cycle #{(path[path.index(nm)..] + [nm]).join(' > ')}"
          return false
        end
        it = items[nm]
        unless it
          problem = parent ? "unknown item #{nm} in #{parent}" : "unknown item #{nm}"
          return false
        end
        if it[0] == :assy
          path.push(nm)
          it[2].each { |c, _| return false unless walk.(c, nm) }
          path.pop
        end
        ok[nm] = true
      end
      unless walk.(f[1], nil)
        puts "line #{n}: cannot build: #{problem}"; next
      end
      uc = lambda do |nm|
        unit[nm] ||= (it = items[nm]; it[0] == :part ? it[1] : it[1] + it[2].sum { |c, q| q * uc.(c) })
      end
      parts = Hash.new(0)
      out = lambda do |nm, q, depth|
        puts "#{'  ' * depth}#{q} x #{nm} = #{money(q * uc.(nm))}"
        it = items[nm]
        if it[0] == :part then parts[nm] += q
        else it[2].each { |c, cq| out.(c, q * cq, depth + 1) } end
      end
      out.(f[1], qty, 0)
      puts "parts:"
      parts.sort_by { |k, v| [-v, k] }.each { |k, v| puts "  #{k} x#{v} = #{money(v * items[k][1])}" }
    end
  else
    err.("unknown command")
  end
end
