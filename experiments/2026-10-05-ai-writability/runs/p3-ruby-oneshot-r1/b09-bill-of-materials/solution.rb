def money(c)
  format("%d.%02d", c / 100, c % 100)
end

NAME_RE = /\A[a-z][a-z0-9_]{0,15}\z/
MONEY_RE = /\A(\d+)\.(\d\d)\z/

def cents(s)
  s =~ MONEY_RE
  $1.to_i * 100 + $2.to_i
end

defs = {}   # name => [:part, cost] or [:assy, labor, [[comp, qty], ...]]
out = []

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = ->(m) { out << "line #{n}: error: #{m}" }
  case f[0]
  when "PART"
    if f.size != 3
      err.("wrong field count")
    elsif f[1] !~ NAME_RE
      err.("bad name")
    elsif f[2] !~ MONEY_RE
      err.("bad cost")
    elsif defs.key?(f[1])
      err.("duplicate #{f[1]}")
    else
      defs[f[1]] = [:part, cents(f[2])]
    end
  when "ASSY"
    if f.size < 4
      err.("wrong field count")
    elsif f[1] !~ NAME_RE
      err.("bad name")
    elsif f[2] !~ MONEY_RE
      err.("bad cost")
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
        err.("bad component #{bad}")
      elsif (dup = comps.map(&:first).tally.find { |_, c| c > 1 })
        err.("repeated component #{dup[0]}")
      elsif defs.key?(f[1])
        err.("duplicate #{f[1]}")
      else
        defs[f[1]] = [:assy, cents(f[2]), comps]
      end
    end
  when "BUILD"
    if f.size != 3
      err.("wrong field count")
    elsif f[1] !~ NAME_RE
      err.("bad name")
    elsif f[2] !~ /\A\d+\z/ || !f[2].to_i.between?(1, 1000)
      err.("bad quantity")
    else
      root = f[1]
      qty = f[2].to_i
      problem = nil
      path = []
      done = {}
      walk = nil
      walk = lambda do |name, parent|
        d = defs[name]
        if d.nil?
          problem = parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}"
          return false
        end
        return true if done[name]
        if (i = path.index(name))
          problem = "cycle " + (path[i..] + [name]).join(" > ")
          return false
        end
        if d[0] == :assy
          path.push(name)
          d[2].each do |c, _|
            unless walk.(c, name)
              path.pop
              return false
            end
          end
          path.pop
        end
        done[name] = true
        true
      end
      if !walk.(root, nil)
        out << "line #{n}: cannot build: #{problem}"
      else
        ucache = {}
        ucost = nil
        ucost = lambda do |name|
          ucache[name] ||= begin
            d = defs[name]
            if d[0] == :part
              d[1]
            else
              d[1] + d[2].sum { |c, q| q * ucost.(c) }
            end
          end
        end
        parts = Hash.new(0)
        emit = nil
        emit = lambda do |name, q, depth|
          out << "#{'  ' * depth}#{q} x #{name} = #{money(q * ucost.(name))}"
          d = defs[name]
          if d[0] == :part
            parts[name] += q
          else
            d[2].each { |c, cq| emit.(c, q * cq, depth + 1) }
          end
        end
        emit.(root, qty, 0)
        out << "parts:"
        parts.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
          out << "  #{nm} x#{q} = #{money(q * defs[nm][1])}"
        end
      end
    end
  else
    err.("unknown command")
  end
end
puts out
