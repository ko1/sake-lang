class InputError < StandardError; end

# Amounts are kept in tenths of a cent; printed rounded to the cent, halves away from zero.
def money(mills)
  sign = mills < 0 ? "-" : ""
  a = (mills.abs + 5) / 10
  format("%s%d.%02d", sign, a / 100, a % 100)
end

# Quantities are kept in tenths.
def qty_s(t) = t % 10 == 0 ? (t / 10).to_s : format("%d.%d", t / 10, t % 10)

def parse_sku(s)
  raise InputError, "bad sku" unless s.match?(/\A[A-Z0-9-]{1,12}\z/)
  s
end

def parse_qty(s)
  m = s.match(/\A(\d+)(?:\.(\d))?\z/)
  t = m && m[1].to_i * 10 + m[2].to_i
  raise InputError, "bad quantity" unless t && t.between?(1, 10_000_000)
  t
end

def parse_price(s)
  m = s.match(/\A(\d+)(?:\.(\d{1,2}))?\z/)
  raise InputError, "bad price" unless m
  m[1].to_i * 100 + (m[2] || "0").ljust(2, "0").to_i
end

def report(lots)
  puts format("%-12s %5s %10s", "SKU", "QTY", "VALUE")
  tq = tv = 0
  lots.keys.sort.each do |sku|
    q = lots[sku].sum { |n, _| n }
    v = lots[sku].sum { |n, c| n * c }
    tq += q
    tv += v
    puts format("%-12s %5s %10s", sku, qty_s(q), money(v))
  end
  puts format("%-12s %5s %10s", "TOTAL", qty_s(tq), money(tv))
end

lots = {} # sku => [[qty, unit_cost], ...] oldest first
revenue = cogs = 0
$stdin.each_line.with_index(1) do |raw, lineno|
  f = raw.split
  next if f.empty?
  begin
    case f[0]
    when "RECEIVE", "SHIP"
      raise InputError, "wrong field count" unless f.size == 4
      sku = parse_sku(f[1])
      qty = parse_qty(f[2])
      price = parse_price(f[3])
      if f[0] == "RECEIVE"
        (lots[sku] ||= []) << [qty, price]
      else
        stock = lots[sku] or raise InputError, "unknown sku #{sku}"
        have = stock.sum { |n, _| n }
        raise InputError, "insufficient stock for #{sku} (have #{qty_s(have)}, need #{qty_s(qty)})" if have < qty
        cost = 0
        left = qty
        while left > 0
          n, c = stock[0]
          take = [n, left].min
          cost += take * c
          left -= take
          if take == n
            stock.shift
          else
            stock[0] = [n - take, c]
          end
        end
        revenue += qty * price
        cogs += cost
        puts "line #{lineno}: shipped #{qty_s(qty)} #{sku}: revenue #{money(qty * price)}, cost #{money(cost)}"
      end
    when "REPORT"
      raise InputError, "wrong field count" unless f.size == 1
      report(lots)
    else
      raise InputError, "unknown command #{f[0]}"
    end
  rescue InputError => e
    puts "line #{lineno}: error: #{e.message}"
  end
end
puts "== final =="
report(lots)
puts "revenue: #{money(revenue)}"
puts "cost of goods sold: #{money(cogs)}"
puts "gross profit: #{money(revenue - cogs)}"
