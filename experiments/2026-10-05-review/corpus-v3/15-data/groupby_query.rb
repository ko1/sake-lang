class Query
  attr_reader :title, :where, :group_by, :aggregates, :order_by, :limit

  def initialize(title, where, group_by, aggregates, order_by, limit)
    @title = title
    @where = where
    @group_by = group_by
    @aggregates = aggregates
    @order_by = order_by
    @limit = limit
  end
end

class QueryError < StandardError
  attr_reader :query

  def initialize(message, query)
    super(message)
    @query = query
  end
end

def rows
  text = <<~TXT
    region=EU product=laptop channel=web units=3 price=1199.0 returned=no
    region=EU product=phone channel=store units=5 price=699.0 returned=no
    region=US product=laptop channel=web units=7 price=1099.0 returned=yes
    region=US product=tablet channel=web units=2 price=449.0 returned=no
    region=APAC product=phone channel=web units=9 price=649.0 returned=no
    region=APAC product=laptop channel=store units=1 price=1249.0 returned=no
    region=EU product=tablet channel=web units=4 price=479.0 returned=yes
    region=US product=phone channel=store units=6 price=679.0 returned=no
    region=APAC product=tablet channel=store units=3 price=429.0 returned=no
    region=US product=laptop channel=store units=2 price=1149.0 returned=no
  TXT
  text.lines.map do |line|
    row = line.split.to_h do |pair|
      k, _eq, v = pair.partition("=")
      value = if v.match?(/\A\d+\z/) then v.to_i
              elsif v.match?(/\A\d+\.\d+\z/) then v.to_f
              else v
              end
      [k, value]
    end
    row["revenue"] = row["units"] * row["price"]
    row
  end
end

def matches?(row, cond)
  field, op, expected = cond
  actual = row[field]
  case op
  in :eq then actual == expected
  in :ne then actual != expected
  in :gt then actual > expected
  in :lt then actual < expected
  end
end

def aggregate(values, fn)
  case fn
  in :count then values.size
  in :sum then values.sum
  in :avg then values.empty? ? nil : values.sum / Float(values.size)
  in :min then values.min
  in :max then values.max
  end
end

def run(q, data)
  q.aggregates.each do |field, fn|
    raise QueryError.new("unknown column #{field}", q.title) unless data.all? { |r| r.key?(field) }
  end
  selected = data.select { |r| q.where.all? { |c| matches?(r, c) } }
  groups = selected.group_by { |r| q.group_by.map { |g| r[g].to_s }.join("/") }
  result = groups.map do |key, members|
    out = { "key" => key }
    q.aggregates.each do |field, fn|
      out["#{fn}(#{field})"] = aggregate(members.map { |m| m[field] }, fn)
    end
    out
  end
  sort_col = q.order_by
  result = result.sort_by { |r| r[sort_col] }.reverse if sort_col
  result.first(q.limit)
end

def cell(v)
  case v
  in Float then format("%12.2f", v)
  in Integer then format("%12d", v)
  in nil then format("%12s", "-")
  in String then format("%-14s", v)
  end
end

def print_result(q, result)
  puts "== #{q.title}"
  if result.empty?
    puts "  (no rows)"
    return
  end
  cols = result.fetch(0).keys
  puts "  " + cols.map { |c| c == "key" ? format("%-14s", q.group_by.join("/")) : format("%12s", c) }.join(" ")
  result.each { |r| puts "  " + cols.map { |c| cell(r[c]) }.join(" ") }
end

def queries
  [
    Query.new("revenue by region", [], ["region"], [["revenue", :sum], ["units", :sum], ["price", :avg]], "sum(revenue)", 10),
    Query.new("web sales by product", [["channel", :eq, "web"]], ["product"], [["units", :sum], ["price", :max]], "sum(units)", 10),
    Query.new("big orders not returned", [["units", :gt, 2], ["returned", :ne, "yes"]], ["region", "channel"], [["units", :count], ["revenue", :sum]], "sum(revenue)", 3),
    Query.new("cheap laptops", [["product", :eq, "laptop"], ["price", :lt, 1000.0]], ["region"], [["price", :min]], nil, 5),
    Query.new("discount report", [], ["product"], [["discount", :avg]], nil, 5)
  ]
end

data = rows
puts "#{data.size} rows loaded"
puts
queries.each do |q|
  begin
    print_result(q, run(q, data))
  rescue QueryError => e
    puts "== #{e.query}"
    puts "  error: #{e.message}"
  end
  puts
end
