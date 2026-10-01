# Validate payment card entries: brand by prefix, length, Luhn checksum, expiry and CVV.
class CardError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

BRANDS = [
  { name: "visa", prefixes: ["4"], lengths: [13, 16], cvv: 3 },
  { name: "mastercard", prefixes: ["51", "52", "53", "54", "55"], lengths: [16], cvv: 3 },
  { name: "amex", prefixes: ["34", "37"], lengths: [15], cvv: 4 }
]

def luhn_valid?(digits)
  sum = digits.chars.reverse.each_with_index.sum do |ch, i|
    d = ch.to_i
    if i.odd?
      d *= 2
      d -= 9 if d > 9
    end
    d
  end
  (sum % 10).zero?
end

def detect_brand(digits)
  BRANDS.find { |brand| brand[:prefixes].any? { |pre| digits.start_with?(pre) } } or
    raise CardError.new("unknown card brand", :brand)
end

# today is given as [year, month]
def check_expiry(text, today)
  m = text.match(%r{\A(\d{2})/(\d{2})\z})
  raise CardError.new("expiry must be MM/YY", :expiry_format) unless m
  month = m[1].to_i
  year = 2000 + m[2].to_i
  raise CardError.new("month #{month} is invalid", :expiry_format) unless month.between?(1, 12)
  if ([year, month] <=> today) < 0
    raise CardError.new("card expired #{month.to_s.rjust(2, "0")}/#{year}", :expired)
  end
  [year, month]
end

def validate_card(number, expiry, cvv, today)
  digits = number.delete(" -")
  raise CardError.new("card number has non-digits", :chars) unless digits.match?(/\A\d+\z/)
  brand = detect_brand(digits)
  name = brand[:name]
  unless brand[:lengths].include?(digits.length)
    raise CardError.new("#{name} numbers have #{brand[:lengths].join(" or ")} digits, got #{digits.length}", :length)
  end
  raise CardError.new("checksum failed", :luhn) unless luhn_valid?(digits)
  check_expiry(expiry, today)
  unless cvv.length == brand[:cvv] && cvv.match?(/\A\d+\z/)
    raise CardError.new("#{name} CVV has #{brand[:cvv]} digits", :cvv)
  end
  [name, "#{"*" * (digits.length - 4)}#{digits[-4..]}"]
end

entries = [
  ["4111 1111 1111 1111", "12/27", "123"],
  ["4111-1111-1111-1112", "12/27", "123"],
  ["5500 0000 0000 0004", "01/26", "999"],
  ["3782 822463 10005", "08/29", "1234"],
  ["3782 822463 10005", "08/29", "123"],
  ["6011 0000 0000 0004", "05/28", "321"],
  ["4111 1111 1111", "05/28", "321"],
  ["4012 8888 8888 1881", "13/27", "555"],
  ["4012 8888 8888 1881", "1227", "555"],
  ["4O12 8888 8888 1881", "12/27", "555"],
  ["5105 1051 0510 5100", "10/26", "042"]
]

today = [2026, 10]
tally = Hash.new(0)
entries.each do |number, expiry, cvv|
  brand, masked = validate_card(number, expiry, cvv, today)
  tally[:ok] += 1
  puts format("%-22s ok    %-10s %s", number, brand, masked)
rescue CardError => e
  tally[e.code] += 1
  puts format("%-22s ERROR %s", number, e.message)
end
puts tally.map { |code, n| "#{code}:#{n}" }.join(" ")
