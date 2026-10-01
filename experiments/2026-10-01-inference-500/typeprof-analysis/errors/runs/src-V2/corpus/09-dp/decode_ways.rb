# "A" = 1 ... "Z" = 26; count and list the ways to read a digit string
def letter(code) = (64 + code).chr

def single_ok?(s, i) = s[i] != "0"

def pair_code(s, i)
  return nil if i + 1 >= s.size || s[i] == "0"
  code = s[i..(i + 1)].to_i
  code <= 26 ? code : nil
end

# ways[i]: readings of the suffix starting at i
def count_ways(s)
  n = s.size
  ways = Array.new(n + 1, 0)
  ways[n] = 1
  (n - 1).downto(0) do |i|
    total = 0
    total += ways[i + 1] if single_ok?(s, i)
    total += ways[i + 2] if pair_code(s, i)
    ways[i] = total
  end
  ways[0]
end

def readings(s, i, memo)
  return [""] if i == s.size
  memo[i] ||= begin
    out = []
    if single_ok?(s, i)
      head = letter(s[i].to_i)
      readings(s, i + 1, memo).each { |rest| out << head + rest }
    end
    code = pair_code(s, i)
    if code
      head = letter(code)
      readings(s, i + 2, memo).each { |rest| out << head + rest }
    end
    out
  end
end

def encode(word) = word.chars.map { |c| (c.ord - 64).to_s }.join

# with "*" standing for any digit 1-9, modulo a prime
def count_wild(s, modulus)
  n = s.size
  ways = Array.new(n + 1, 0)
  ways[n] = 1
  (n - 1).downto(0) do |i|
    c = s[i]
    single = c == "*" ? 9 : (c == "0" ? 0 : 1)
    total = single * ways[i + 1]
    if i + 1 < n
      d = s[i + 1]
      pairs =
        if c == "*" && d == "*"
          15
        elsif c == "*"
          d.to_i <= 6 ? 2 : 1
        elsif d == "*"
          c == "1" ? 9 : (c == "2" ? 6 : 0)
        else
          c != "0" && (c + d).to_i <= 26 ? 1 : 0
        end
      total += pairs * ways[i + 2]
    end
    ways[i] = total % modulus
  end
  ways[0]
end

inputs = ["12", "226", "06", "11106", "1201234", "27", "100", "2611055971756562"]
inputs.each do |s|
  n = count_ways(s)
  line = format("%-18s %5d", s, n)
  line += "  " + readings(s, 0, {}).sort.join(" ") if n > 0 && n <= 6
  puts line
end

%w[DYNAMIC TABLE KNAPSACK].each do |word|
  code = encode(word)
  n = count_ways(code)
  others = readings(code, 0, {}).reject { |r| r == word }
  puts "#{word} -> #{code}: #{n} readings, e.g. #{others.sort.take(3).join(", ")}"
end

modulus = 1_000_000_007
["*", "1*", "**", "*1*0", "2*2*2*2*", "***********"].each do |s|
  puts format("%-12s %d", s, count_wild(s, modulus))
end
puts "80 ones: #{count_ways("1" * 80)}"
