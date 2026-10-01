class Fact
  attr_reader :date_key, :store_key, :product_key, :qty, :net_cents

  def initialize(date_key, store_key, product_key, qty, net_cents)
    @date_key = date_key
    @store_key = store_key
    @product_key = product_key
    @qty = qty
    @net_cents = net_cents
  end
end

class Dimension
  attr_reader :name, :by_natural, :rows

  def initialize(name)
    @name = name
    @by_natural = {}
    @rows = []
  end

  def key_for(natural, attrs)
    existing = by_natural[natural]
    return existing if existing
    key = rows.size + 1
    by_natural[natural] = key
    rows << [key, natural, attrs]
    key
  end

  def attrs(key)
    _k, _natural, a = rows.fetch(key - 1)
    a
  end
end

class LoadError_ < StandardError
  attr_reader :source, :line_no

  def initialize(message, source, line_no)
    super(message)
    @source = source
    @line_no = line_no
  end
end

def pos_feed
  <<~TXT
    2026-07-01|S01|SKU-1|2|3.50
    2026-07-01|S01|SKU-2|1|12.00
    2026-07-01|S02|SKU-1|5|3.50
    2026-07-02|S02|SKU-3|1|45.00
    2026-07-02|S03|SKU-2|2|12.00
    2026-07-03|S01|SKU-4|3|7.25
    2026-07-03|S9X|SKU-1|1|3.50
    2026-07-04|S03|SKU-1|4|3.50
    2026-07-04|S03|SKU-3|1|42.00
  TXT
end

def web_feed
  <<~TXT
    {"day":"2026-07-01","sku":"sku-2","qty":3,"total_cents":3600,"coupon":"SUMMER"}
    {"day":"2026-07-02","sku":"sku-4","qty":1,"total_cents":725}
    {"day":"2026-07-03","sku":"sku-1","qty":10,"total_cents":3150,"coupon":"BULK"}
    {"day":"2026-07-04","sku":"sku-5","qty":1,"total_cents":999}
    {"day":"2026-07-04","sku":"sku-3","qty":"two","total_cents":9000}
  TXT
end

def stores = { "S01" => ["Downtown", "north"], "S02" => ["Harbor", "south"], "S03" => ["Airport", "north"], "WEB" => ["Online", "online"] }
def products = { "SKU-1" => ["Croissant", "bakery"], "SKU-2" => ["Coffee beans", "grocery"], "SKU-3" => ["Espresso cup set", "homeware"], "SKU-4" => ["Jam", "grocery"] }

def to_cents(s)
  whole, _dot, frac = s.partition(".")
  whole.to_i * 100 + frac.ljust(2, "0").to_i
end

def json_field(line, name)
  m = line.match(Regexp.new("\"#{name}\":(\"([^\"]*)\"|(-?\\d+))"))
  return nil if !m    
  m[2] || (m[3] || "0").to_i
end

def extract_pos(text)
  text.lines.each_with_index.map do |line, i|
    parts = line.chomp.split("|")
    raise LoadError_.new("expected 5 fields", "pos", i + 1) if parts.size != 5
    day, store, sku, qty_s, price = parts
    qty = qty_s.to_i
    { day: day, store: store, sku: sku, qty: qty, cents: to_cents(price) * qty }
  end
end

def extract_web(text, rejects)
  records = []
  text.lines.each_with_index do |line, i|
    day = json_field(line, "day")
    sku = json_field(line, "sku")
    qty = json_field(line, "qty")
    cents = json_field(line, "total_cents")
    raise LoadError_.new("qty is not a number", "web", i + 1) unless qty in Integer
    raise LoadError_.new("missing fields", "web", i + 1) unless (day in String) && (sku in String) && (cents in Integer)
    records << { day: day, store: "WEB", sku: sku.upcase, qty: qty, cents: cents }
  rescue LoadError_ => e
    rejects << e
  end
  records
end

def load(records, dims, facts, rejects)
  dates, store_dim, product_dim = dims
  records.each do |r|
    store_info = stores[r[:store]]
    product_info = products[r[:sku]]
    if !store_info     || !product_info    
      what = !store_info     ? "store #{r[:store]}" : "product #{r[:sku]}"
      rejects << LoadError_.new("unknown #{what}", "load", 0)
      next
    end
    sname, region = store_info
    pname, category = product_info
    day = r[:day]
    t = Time.new(day[0..3].to_i, day[5..6].to_i, day[8..9].to_i)
    dk = dates.key_for(day, [t.strftime("%a"), t.saturday? || t.sunday?])
    sk = store_dim.key_for(r[:store], [sname, region])
    pk = product_dim.key_for(r[:sku], [pname, category])
    facts << Fact.new(dk, sk, pk, r[:qty], r[:cents])
  end
end

def money(c) = format("%d.%02d", c / 100, c % 100)

def rollup(facts, header)
  totals = Hash.new(0)
  units = Hash.new(0)
  facts.each do |f|
    k = yield(f)
    totals[k] += f.net_cents
    units[k] += f.qty
  end
  grand = totals.values.sum
  puts header
  totals.sort_by { |k, v| -v }.each do |k, v|
    puts format("  %-18s %4d units %9s %5.1f%%", k, units[k], money(v), v * 100.0 / grand)
  end
end

rejects = []
records = []
begin
  records.concat(extract_pos(pos_feed))
rescue LoadError_ => e
  rejects << e
end
records.concat(extract_web(web_feed, rejects))

dates = Dimension.new("date")
store_dim = Dimension.new("store")
product_dim = Dimension.new("product")
facts = []
load(records, [dates, store_dim, product_dim], facts, rejects)

puts "Extracted #{records.size} records, loaded #{facts.size} facts, rejected #{rejects.size}"
[dates, store_dim, product_dim].each do |d|
  puts format("  dim_%-8s %d rows", d.name, d.rows.size)
end
puts
rollup(facts, "Revenue by store") { |f| store_dim.attrs(f.store_key)[0] }
puts
rollup(facts, "Revenue by category") { |f| product_dim.attrs(f.product_key)[1] }
puts
rollup(facts, "Revenue by day") do |f|
  a = dates.attrs(f.date_key)
  "#{a[0]}#{a[1] ? " (weekend)" : ""}"
end
puts
puts "Region x category units:"
cross = Hash.new(0)
facts.each do |f|
  region = store_dim.attrs(f.store_key)[1]
  category = product_dim.attrs(f.product_key)[1]
  cross[[region, category]] += f.qty
end
regions = cross.keys.map { |r, c| r }.uniq.sort
categories = cross.keys.map { |r, c| c }.uniq.sort
puts format("  %-8s", "") + categories.map { |c| format("%10s", c) }.join
regions.each do |r|
  puts format("  %-8s", r) + categories.map { |c| format("%10d", cross[[r, c]]) }.join
end
puts
puts "Rejected:"
rejects.each do |e|
  where = e.line_no > 0 ? "#{e.source}:#{e.line_no}" : e.source
  puts "  #{where} #{e.message}"
end
