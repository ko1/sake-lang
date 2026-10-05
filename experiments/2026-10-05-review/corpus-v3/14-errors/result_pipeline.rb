# Railway-style validation: each step returns {ok: value} or {error: reason}, and steps chain until one fails.
def ok(v) = { ok: v }
def err(msg) = { error: msg }

def and_then(result)
  case result
  in { ok: } then yield ok
  in { error: } then result
  end
end

CATALOG = { "PEN" => 120, "INK" => 480, "PAD" => 350, "BAG" => 2900 }
COUPONS = { "SAVE10" => 10, "SAVE25" => 25, "NONE" => 0 }
CREDIT = { "acme" => 5000, "zeta" => 1000, "nova" => 20000 }

def parse_order(line)
  fields = line.split(";")
  return err("expected 4 fields, got #{fields.size}") if fields.size != 4
  ok(fields.map(&:strip))
end

def parse_quantity(fields)
  q = Integer(fields[2], exception: false)
  return err("quantity '#{fields[2]}' is not a number") if q.nil?
  return err("quantity must be positive") if q <= 0
  ok({ customer: fields[0], sku: fields[1], qty: q, coupon: fields[3] })
end

def lookup_price(order)
  price = CATALOG[order[:sku]]
  return err("unknown sku #{order[:sku]}") unless price
  ok(order.merge(subtotal: price * order[:qty]))
end

def apply_coupon(order)
  order => { coupon:, subtotal:, customer:, sku:, qty: }
  return ok({ customer:, sku:, qty:, total: subtotal }) if coupon == "-"
  rate = COUPONS[coupon]
  return err("coupon #{coupon} is not valid") unless rate
  return err("coupon #{coupon} needs a subtotal of 2000 (have #{subtotal})") if rate > 0 && subtotal < 2000
  ok({ customer:, sku:, qty:, total: subtotal - subtotal * rate / 100 })
end

def check_credit(order)
  order => { customer:, total: }
  limit = CREDIT[customer]
  return err("no credit line for #{customer}") unless limit
  return err("#{customer} would exceed credit (#{total} > #{limit})") if total > limit
  ok(order)
end

def process(line)
  r = parse_order(line)
  r = and_then(r) { parse_quantity(_1) }
  r = and_then(r) { lookup_price(_1) }
  r = and_then(r) { apply_coupon(_1) }
  and_then(r) { check_credit(_1) }
end

lines = [
  "acme; PEN; 10; -",
  "acme; BAG; 2; SAVE10",
  "zeta; INK; 3; SAVE25",
  "nova; PAD; x; -",
  "nova; CUP; 1; -",
  "zeta; PEN; 5; HALF",
  "zeta; PAD; 4; NONE",
  "omni; PEN; 1; -",
  "acme; PAD",
  "nova; BAG; 6; SAVE25",
  "acme; INK; 0; -"
]

accepted = []
reasons = Hash.new(0)
lines.each.with_index(1) do |line, n|
  case process(line)
  in { ok: { customer:, sku:, qty:, total: } }
    accepted << total
    puts format("%2d ok    %-5s %s x%-3d %6d", n, customer, sku, qty, total)
  in { error: }
    reasons[error.split(" ").first] += 1
    puts format("%2d error %s", n, error)
  end
end
puts "accepted #{accepted.size}, revenue #{accepted.sum}"
puts "errors by first word: #{reasons.map { |w, c| "#{w}:#{c}" }.join(" ")}"
