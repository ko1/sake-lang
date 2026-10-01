class Person
  attr_reader :id, :first, :last

  def initialize(id, first, last)
    @id = id
    @first = first
    @last = last
  end
end

def code_table
  table = {}
  groups = { "1" => "bfpv", "2" => "cgjkqsxz", "3" => "dt", "4" => "l", "5" => "mn", "6" => "r" }
  groups.each { |digit, letters| letters.each_char { |c| table[c] = digit } }
  table
end

def soundex(name, table)
  s = name.gsub(/[^A-Za-z]/, "").downcase
  return "0000" if s.empty?
  first = s[0].upcase
  digits = ""
  prev = table[s[0]]
  s.chars.drop(1).each do |c|
    d = table[c]
    if d
      digits += d if d != prev
      prev = d
    elsif c != "h" && c != "w"
      prev = nil
    end
  end
  (first + digits).ljust(4, "0")[0..3]
end

def people
  [
    Person.new(1, "Robert", "Rupert"), Person.new(2, "Ann", "Ashcraft"), Person.new(3, "Tom", "Tymczak"),
    Person.new(4, "Jo", "Pfister"), Person.new(5, "Eva", "Robert"), Person.new(6, "Li", "Lee"),
    Person.new(7, "Sam", "Smith"), Person.new(8, "Kim", "Smyth"), Person.new(9, "Pat", "Schmidt"),
    Person.new(10, "Al", "Ashcroft"), Person.new(11, "Max", "Lea"), Person.new(12, "Ida", "Honeyman"),
    Person.new(13, "Bo", "Rubin"), Person.new(14, "Cy", "Smithe"), Person.new(15, "Di", "Tymczack")
  ]
end

table = code_table
index = {}
people.each do |pr|
  (index[soundex(pr.last, table)] ||= []) << pr
end

puts "reference codes:"
["Robert", "Rupert", "Rubin", "Ashcraft", "Tymczak", "Pfister", "Honeyman"].each do |n|
  puts "  #{n.ljust(9)} #{soundex(n, table)}"
end

puts "index (#{index.size} codes):"
index.keys.sort.each do |code|
  names = index[code].map { |pr| "#{pr.first} #{pr.last}" }
  puts "  #{code}: #{names.join("; ")}"
end

spellings = {}
index.each do |code, list|
  variants = list.map(&:last).uniq
  spellings[code] = variants if variants.size > 1
end
puts "possible duplicate surnames:"
spellings.each { |code, vs| puts "  #{code} #{vs.sort.join(" ~ ")}" }

def lookup(index, table, query)
  found = index[soundex(query, table)]
  return "none" unless found
  "ids #{found.map(&:id).join(",")}"
end

["Smitt", "Robbert", "Leigh", "Ashcroff", "Zhang", ""].each do |q|
  puts format("lookup %-10s -> %s", "'#{q}'", lookup(index, table, q))
end
