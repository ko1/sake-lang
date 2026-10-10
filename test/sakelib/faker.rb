require_relative "ref/faker"

# Every pick draws Kernel.rand, so a seed fixes the whole sequence; the Sake twin draws the same numbers.
Faker.seed(42)
puts "name: #{Faker::Name.name}"
puts "first/last: #{Faker::Name.first_name} #{Faker::Name.last_name}"
puts "prefix/suffix: #{Faker::Name.prefix} #{Faker::Name.suffix}"
puts "middle: #{Faker::Name.name_with_middle}"
puts "initials: #{Faker::Name.initials} #{Faker::Name.initials(2)}"
5.times { puts "name #{Faker::Name.name}" }

puts "email: #{Faker::Internet.email}"
puts "email(name): #{Faker::Internet.email("Jane Doe")}"
puts "email(name, domain): #{Faker::Internet.email("Jane Doe", "example.com")}"
puts "free_email: #{Faker::Internet.free_email}"
puts "username: #{Faker::Internet.username}"
puts "username(spec): #{Faker::Internet.username("Nancy O'Neil", ["-"])}"
puts "domain: #{Faker::Internet.domain_name} #{Faker::Internet.domain_word} #{Faker::Internet.domain_suffix}"
puts "ip: #{Faker::Internet.ip_v4_address}"
puts "mac: #{Faker::Internet.mac_address}"
puts "url: #{Faker::Internet.url}"
puts "url(host, path, scheme): #{Faker::Internet.url("example.org", "/x", "https")}"
puts "password: #{Faker::Internet.password} #{Faker::Internet.password(12)}"
puts "slug: #{Faker::Internet.slug} #{Faker::Internet.slug("Hello Big World", ".")}"

puts "word: #{Faker::Lorem.word}"
p Faker::Lorem.words
p Faker::Lorem.words(5)
puts "sentence: #{Faker::Lorem.sentence}"
puts "sentence(2): #{Faker::Lorem.sentence(2)}"
puts "sentence(3, 4): #{Faker::Lorem.sentence(3, 4)}"
p Faker::Lorem.sentences(2)
puts "paragraph: #{Faker::Lorem.paragraph}"
puts "paragraph(1, 2): #{Faker::Lorem.paragraph(1, 2)}"
p Faker::Lorem.paragraphs(2)
puts "question: #{Faker::Lorem.question(3)}"
puts "characters: #{Faker::Lorem.characters(16)}"

p Faker::Number.number
p Faker::Number.number(3)
p Faker::Number.number(1)
p Faker::Number.leading_zero_number(6)
p Faker::Number.decimal
p Faker::Number.decimal(2, 1)
p Faker::Number.decimal(3, 4)
p Faker::Number.between
p Faker::Number.between(1, 6)
p Faker::Number.between(-10, 10)
p Faker::Number.within(1..3)
p Faker::Number.within(1...3)
p Faker::Number.positive
p Faker::Number.positive(0.0, 1.0)
p Faker::Number.negative
p Faker::Number.digit
p Faker::Number.non_zero_digit
p Faker::Number.hexadecimal
p Faker::Number.hexadecimal(2)
p Faker::Number.binary
begin
  Faker::Number.number(0)
rescue ArgumentError => e
  puts "ArgumentError: #{e.message}"
end

4.times { puts "city: #{Faker::Address.city}" }
puts "street_address: #{Faker::Address.street_address}"
puts "street_address(secondary): #{Faker::Address.street_address(true)}"
puts "street_name: #{Faker::Address.street_name}"
puts "building_number: #{Faker::Address.building_number}"
puts "zip: #{Faker::Address.zip_code} #{Faker::Address.zip} #{Faker::Address.postcode}"
puts "state: #{Faker::Address.state} (#{Faker::Address.state_abbr})"
puts "country: #{Faker::Address.country}"
puts "full: #{Faker::Address.full_address}"
p Faker::Address.latitude.round(6)
p Faker::Address.longitude.round(6)

4.times { puts "company: #{Faker::Company.name}" }
puts "suffix: #{Faker::Company.suffix}"
puts "industry: #{Faker::Company.industry}"
puts "bs: #{Faker::Company.bs}"
puts "catch_phrase: #{Faker::Company.catch_phrase}"
puts "ein: #{Faker::Company.ein}"

p Array.new(6) { Faker::Boolean.boolean }
p Faker::Boolean.boolean(1.0)
p Faker::Boolean.boolean(0.0)
puts "color: #{Faker::Color.color_name} #{Faker::Color.hex_color}"
p Faker::Color.rgb_color

p Faker.numerify("###-####")
p Faker.letterify("???")
p Faker.bothify("?#?#")
p Faker.pick_distinct(%w[a b c d], 3)
p Faker.pick_distinct(%w[a b], 5)

# the same seed gives the same sequence again
Faker.seed(42)
first = Faker::Name.name
Faker.seed(42)
p first == Faker::Name.name
Faker.seed(7)
puts "seed 7: #{Faker::Name.name}, #{Faker::Internet.email}, #{Faker::Address.city}"
