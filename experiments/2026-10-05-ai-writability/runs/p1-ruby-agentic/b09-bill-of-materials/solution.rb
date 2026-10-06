def money(c) = format("%d.%02d", c / 100, c % 100)
def cents(s) = s =~ /\A(\d+)\.(\d\d)\z/ ? $1.to_i * 100 + $2.to_i : nil

NAME = /\A[a-z][a-z0-9_]{0,15}\z/
defs = {}  # name => [:part, cost] | [:assy, labor, [[name, qty], ...]]

class Stop < StandardError; end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = nil
  case f[0]
  when "PART"
    if f.size != 3 then err = "wrong field count"
    elsif f[1] !~ NAME then err = "bad name"
    elsif !(c = cents(f[2])) then err = "bad cost"
    elsif defs[f[1]] then err = "duplicate #{f[1]}"
    else defs[f[1]] = [:part, c]
    end
  when "ASSY"
    if f.size < 4 then err = "wrong field count"
    elsif f[1] !~ NAME then err = "bad name"
    elsif !(c = cents(f[2])) then err = "bad cost"
    else
      comps = []
      f[3..].each do |t|
        if t =~ /\A([a-z][a-z0-9_]{0,15}):(\d+)\z/ && (1..999).cover?($2.to_i)
          comps << [$1, $2.to_i]
        else
          err = "bad component #{t}"
          break
        end
      end
      if !err
        seen = {}
        comps.each do |cn, _|
          if seen[cn]
            err = "repeated component #{cn}"
            break
          end
          seen[cn] = true
        end
      end
      err ||= "duplicate #{f[1]}" if !err && defs[f[1]]
      defs[f[1]] = [:assy, c, comps] unless err
    end
  when "BUILD"
    if f.size != 3 then err = "wrong field count"
    elsif f[1] !~ NAME then err = "bad name"
    elsif f[2] !~ /\A\d+\z/ || !(1..1000).cover?(f[2].to_i) then err = "bad quantity"
    else
      qty = f[2].to_i
      ok = {}
      path = []
      walk = lambda do |name, parent|
        d = defs[name]
        raise Stop, "unknown item #{name}#{parent ? " in #{parent}" : ""}" unless d
        if (i = path.index(name))
          raise Stop, "cycle #{(path[i..] + [name]).join(' > ')}"
        end
        next if ok[name] || d[0] == :part
        path.push(name)
        d[2].each { |cn, _| walk.(cn, name) }
        path.pop
        ok[name] = true
      end
      begin
        walk.(f[1], nil)
      rescue Stop => e
        puts "line #{n}: cannot build: #{e.message}"
        next
      end
      unit = {}
      uc = lambda do |name|
        unit[name] ||= defs[name][0] == :part ? defs[name][1] :
          defs[name][1] + defs[name][2].sum { |cn, q| q * uc.(cn) }
      end
      totals = Hash.new(0)
      show = lambda do |name, q, depth|
        puts "#{'  ' * depth}#{q} x #{name} = #{money(q * uc.(name))}"
        if defs[name][0] == :part
          totals[name] += q
        else
          defs[name][2].each { |cn, cq| show.(cn, q * cq, depth + 1) }
        end
      end
      show.(f[1], qty, 0)
      puts "parts:"
      totals.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
        puts "  #{nm} x#{q} = #{money(q * defs[nm][1])}"
      end
    end
  else
    err = "unknown command"
  end
  puts "line #{n}: error: #{err}" if err
end
