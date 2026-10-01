# Check-digit schemes: Luhn (cards), ISBN-10, ISBN-13/EAN-13, and generating missing digits.

module CheckDigit
  module_function

  def digits_of(s) = s.delete(" -").chars.map { |c| c == "X" ? 10 : c.to_i }

  def luhn_sum(digits)
    digits.reverse.each_with_index.sum do |d, i|
      if i.odd?
        d2 = d * 2
        d2 > 9 ? d2 - 9 : d2
      else
        d
      end
    end
  end

  def luhn_valid?(s) = luhn_sum(digits_of(s)) % 10 == 0

  def luhn_complete(partial)
    c = (10 - luhn_sum(digits_of(partial) + [0]) % 10) % 10
    "#{partial}#{c}"
  end

  def isbn10_valid?(s)
    ds = digits_of(s)
    return false if ds.size != 10
    return false if ds.take(9).any? { |d| d == 10 }
    ds.each_with_index.sum { |d, i| d * (10 - i) } % 11 == 0
  end

  def ean13_valid?(s)
    ds = digits_of(s)
    return false if ds.size != 13
    ds.each_with_index.sum { |d, i| i.even? ? d : d * 3 } % 10 == 0
  end

  def isbn10_to_13(s)
    body = [9, 7, 8] + digits_of(s).take(9)
    total = body.each_with_index.sum { |d, i| i.even? ? d : d * 3 }
    body << (10 - total % 10) % 10
    body.join
  end

  def card_brand(s)
    clean = s.delete(" -")
    if clean.start_with?("4")
      :visa
    elsif clean.match?(/\A5[1-5]/)
      :mastercard
    elsif clean.match?(/\A3[47]/)
      :amex
    end
  end
end

def classify(code)
  kind, value = code
  case kind
  in :card
    brand = CheckDigit.card_brand(value)
    { ok: CheckDigit.luhn_valid?(value), label: brand ? brand.to_s : "unknown" }
  in :isbn10
    { ok: CheckDigit.isbn10_valid?(value), label: "isbn-10" }
  in :ean13
    { ok: CheckDigit.ean13_valid?(value), label: "ean-13" }
  end
end

codes = [
  [:card, "4539 1488 0343 6467"],
  [:card, "4539 1488 0343 6468"],
  [:card, "5555-5555-5555-4444"],
  [:card, "3782 822463 10005"],
  [:card, "6011 1111 1111 1117"],
  [:isbn10, "0-306-40615-2"],
  [:isbn10, "0-8044-2957-X"],
  [:isbn10, "0-306-40615-3"],
  [:ean13, "978-0-306-40615-7"],
  [:ean13, "4006381333931"],
  [:ean13, "4006381333932"]
]

valid = 0
by_label = Hash.new(0)
codes.each do |code|
  r = classify(code)
  valid += 1 if r[:ok]
  by_label[r[:label]] += 1
  puts format("%-7s %-22s %-10s %s", code[0].to_s, code[1], r[:label], r[:ok] ? "valid" : "INVALID")
end
puts "#{valid} of #{codes.size} valid"
by_label.each { |label, n| puts "  #{label}: #{n}" }

puts "-- completing --"
["7992739871", "453914880343646", "37828224631000"].each do |partial|
  full = CheckDigit.luhn_complete(partial)
  puts "#{partial} -> #{full} (#{CheckDigit.luhn_valid?(full)})"
end
["0-306-40615-2", "0-8044-2957-X", "1-56619-909-3"].each do |isbn|
  converted = CheckDigit.isbn10_to_13(isbn)
  puts "#{isbn} -> #{converted} (#{CheckDigit.ean13_valid?(converted)})"
end
