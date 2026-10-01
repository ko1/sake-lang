# Check-digit schemes: Luhn (cards), ISBN-10 (mod 11 with X), ISBN-13 / EAN (weights 1,3),
# and mod 97 (IBAN-style). Validates, computes, and detects typos.

def luhn_sum(digits)
  total = 0
  digits.reverse.each_with_index do |d, i|
    if i.odd?
      d *= 2
      d -= 9 if d > 9
    end
    total += d
  end
  total
end

def luhn_valid?(s)
  ds = digits_of(s)
  !ds.nil? && luhn_sum(ds) % 10 == 0
end

def luhn_complete(s)
  ds = digits_of(s)
  ds << 0
  check = (10 - luhn_sum(ds) % 10) % 10
  "#{s}#{check}"
end

def digits_of(s)
  clean = s.delete(" -")
  return nil unless clean.match?(/\A\d+\z/)
  clean.chars.map(&:to_i)
end

def isbn10_check(s)
  clean = s.delete("-")
  return :bad_length if clean.length != 10
  total = 0
  clean.chars.each_with_index do |c, i|
    v = if c == "X" && i == 9
      10
    elsif c.match?(/\d/)
      c.to_i
    else
      return :bad_char
    end
    total += v * (10 - i)
  end
  total % 11 == 0 ? :ok : :bad_check
end

def isbn13_check(s)
  ds = digits_of(s)
  return :bad_char unless ds
  return :bad_length if ds.size != 13
  total = 0
  ds.each_with_index { |d, i| total += i.even? ? d : 3 * d }
  total % 10 == 0 ? :ok : :bad_check
end

def isbn10_to_13(s)
  core = "978" + s.delete("-")[0, 9]
  total = 0
  digits_of(core).each_with_index { |d, i| total += i.even? ? d : 3 * d }
  "#{core}#{(10 - total % 10) % 10}"
end

def mod97_valid?(s)
  rem = 0
  s.delete(" ").each_char { |c| rem = (rem * 10 + c.to_i) % 97 }
  rem == 1
end

def describe(result)
  case result
  in :ok then "valid"
  in :bad_check then "check digit mismatch"
  in :bad_length then "wrong length"
  in :bad_char then "invalid character"
  end
end

puts "Luhn:"
["4539 1488 0343 6467", "8273 1232 7352 0569", "79927398713", "1234-5678-9012-3456", "12a4"].each do |s|
  puts format("  %-22s %s", s, luhn_valid?(s) ? "valid" : "invalid")
end
["7992739871", "4111111111111"].each { |s| puts "  complete #{s} -> #{luhn_complete(s)}" }

puts "ISBN:"
["0-306-40615-2", "0-306-40615-3", "0-8044-2957-X", "123456789", "0-30A-40615-2"].each do |s|
  puts format("  %-16s %s", s, describe(isbn10_check(s)))
end
["978-0-306-40615-7", "978-0-306-40615-8", "978-3-16-148410-0", "97803064061"].each do |s|
  puts format("  %-20s %s", s, describe(isbn13_check(s)))
end
puts "  0-306-40615-2 as ISBN-13: #{isbn10_to_13("0-306-40615-2")}"

puts "single-digit typo detection on 79927398713:"
base = "79927398713"
caught = 0
total = 0
base.length.times do |i|
  (0..9).each do |d|
    next if d == base[i].to_i
    typo = base.dup
    typo[i] = d.to_s
    total += 1
    caught += 1 unless luhn_valid?(typo)
  end
end
puts "  #{caught}/#{total} caught"

swaps = 0
missed = []
(base.length - 1).times do |i|
  cs = base.chars
  next if cs[i] == cs[i + 1]
  cs[i], cs[i + 1] = cs[i + 1], cs[i]
  swaps += 1
  missed << "#{cs[i + 1]}#{cs[i]}" if luhn_valid?(cs.join)
end
puts "  adjacent swaps: #{swaps}, missed: #{missed}"

puts "mod 97:"
["3214282912345698765432161182", "3214282912345698765432161183"].each do |s|
  puts "  #{s}: #{mod97_valid?(s) ? "valid" : "invalid"}"
end
