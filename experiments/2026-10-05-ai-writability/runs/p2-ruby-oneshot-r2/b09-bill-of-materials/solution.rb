def money(c) = format("%d.%02d", c / 100, c % 100)

NAME_RE = /\A[a-z][a-z0-9_]{0,15}\z/
MONEY_RE = /\A\d+\.\d\d\z/

items = {}   # name => [:part, cost] | [:assy, labor, [[comp, qty], ...]]
unit = {}
verified = {}

class Stop < StandardError; end

check = nil
check = lambda do |name, path, parent|
  it = items[name]
  if it.nil?
    raise Stop, (parent ? "unknown item #{name} in #{parent}" : "unknown item #{name}")
  end
  if (i = path.index(name))
    raise Stop, "cycle " + (path[i..] + [name]).join(" > ")
  end
  next if verified[name] || it[0] == :part
  path.push(name)
  it[2].each { |c, _| check.(c, path, name) }
  path.pop
  verified[name] = true
end

unit_cost = lambda do |name|
  unit[name] ||= begin
    it = items[name]
    if it[0] == :part
      it[1]
    else
      it[1] + it[2].sum { |c, q| q * unit_cost.(c) }
    end
  end
end

$stdin.each_line.with_index(1) do |raw, n|
  f = raw.split
  next if f.empty?
  err = nil
  case f[0]
  when "PART"
    if f.size != 3 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !f[2].match?(MONEY_RE) then err = "bad cost"
    elsif items.key?(f[1]) then err = "duplicate #{f[1]}"
    else
      items[f[1]] = [:part, f[2].delete(".").to_i]
    end
  when "ASSY"
    if f.size < 4 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !f[2].match?(MONEY_RE) then err = "bad cost"
    else
      comps = []
      f[3..].each do |t|
        md = t.match(/\A([a-z][a-z0-9_]{0,15}):(\d+)\z/)
        if md.nil? || !md[2].to_i.between?(1, 999)
          err = "bad component #{t}"
          break
        end
        comps << [md[1], md[2].to_i]
      end
      if err.nil?
        dup = comps.map(&:first).tally.find { |_, c| c > 1 }
        # first name that is repeated, in listed order
        rep = comps.map(&:first).find { |c| comps.count { |x, _| x == c } > 1 }
        if rep then err = "repeated component #{rep}"
        elsif items.key?(f[1]) then err = "duplicate #{f[1]}"
        else
          items[f[1]] = [:assy, f[2].delete(".").to_i, comps]
        end
      end
    end
  when "BUILD"
    if f.size != 3 then err = "wrong field count"
    elsif !f[1].match?(NAME_RE) then err = "bad name"
    elsif !(f[2].match?(/\A\d+\z/) && f[2].to_i.between?(1, 1000)) then err = "bad quantity"
    else
      begin
        check.(f[1], [], nil)
        qty = f[2].to_i
        parts = Hash.new(0)
        show = nil
        show = lambda do |name, q, depth|
          puts "#{'  ' * depth}#{q} x #{name} = #{money(q * unit_cost.(name))}"
          it = items[name]
          if it[0] == :part
            parts[name] += q
          else
            it[2].each { |c, cq| show.(c, q * cq, depth + 1) }
          end
        end
        show.(f[1], qty, 0)
        puts "parts:"
        parts.sort_by { |nm, q| [-q, nm] }.each do |nm, q|
          puts "  #{nm} x#{q} = #{money(q * unit_cost.(nm))}"
        end
      rescue Stop => e
        puts "line #{n}: cannot build: #{e.message}"
      end
    end
  else
    err = "unknown command"
  end
  puts "line #{n}: error: #{err}" if err
end
