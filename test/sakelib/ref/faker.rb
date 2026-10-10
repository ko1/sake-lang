# Reference implementation of sakelib/faker.sake in plain Ruby, for test/sakelib/faker.rb: the same word lists
# and the same draws from Kernel#rand in the same order, so a seed gives the same data as the Sake port.
# (The faker gem's lists are far larger; its output cannot be matched. This is a subset of its API.)

module Faker
  module_function

  def seed(n) = Kernel.srand(n)
  def pick(list) = list.fetch(rand(list.size))
  def numerify(s) = s.gsub("#") { rand(10).to_s }
  def letterify(s) = s.gsub("?") { (65 + rand(26)).chr }
  def bothify(s) = letterify(numerify(s))

  def pick_distinct(list, n)
    out = []
    pool = list.dup
    while out.size < n && !pool.empty?
      i = rand(pool.size)
      out.push(pool.fetch(i))
      pool.delete_at(i)
    end
    out
  end
end

module Faker::Name
  module_function

  FIRST_NAMES = %w[Alice Bob Carol David Emma Frank Grace Henry Iris Jack Karen Liam Mia Noah Olivia Paul Quinn Rose Sam Tina]
  LAST_NAMES = %w[Anderson Brown Clark Davis Evans Fisher Garcia Hill Irwin Jones King Lewis Miller Nelson Owens Parker Quinn Reed Smith Turner]
  PREFIXES = %w[Mr. Mrs. Ms. Miss Dr.]
  SUFFIXES = %w[Jr. Sr. I II III MD DDS PhD DVM]

  def first_names = FIRST_NAMES
  def last_names = LAST_NAMES
  def first_name = Faker.pick(FIRST_NAMES)
  def last_name = Faker.pick(LAST_NAMES)
  def prefix = Faker.pick(PREFIXES)
  def suffix = Faker.pick(SUFFIXES)

  def name
    case rand(5)
    when 0 then "#{prefix} #{first_name} #{last_name}"
    when 1 then "#{first_name} #{last_name} #{suffix}"
    else "#{first_name} #{last_name}"
    end
  end

  def name_with_middle = "#{first_name} #{first_name} #{last_name}"
  def initials(number = 3) = Faker.letterify("?" * number)
end

module Faker::Internet
  module_function

  DOMAIN_SUFFIXES = %w[com net org io dev info]
  FREE_EMAIL_DOMAINS = %w[gmail.com yahoo.com hotmail.com]
  SEPARATORS = %w[. _]

  def separators = SEPARATORS

  def username(specifier = nil, seps = separators)
    parts = specifier.nil? ? [first_part, last_part] : specifier.split(" ")
    sep = Faker.pick(seps)
    parts.map { |x| x.gsub(/[^A-Za-z0-9]/, "") }.join(sep).downcase
  end

  def first_part = Faker::Name.first_name
  def last_part = Faker::Name.last_name

  def email(name = nil, domain = nil)
    u = username(name)
    d = domain.nil? ? domain_name : domain
    "#{u}@#{d}"
  end

  def free_email(name = nil) = "#{username(name)}@#{Faker.pick(FREE_EMAIL_DOMAINS)}"

  def domain_word = Faker::Name.last_name.gsub(/[^A-Za-z]/, "").downcase
  def domain_suffix = Faker.pick(DOMAIN_SUFFIXES)
  def domain_name = "#{domain_word}.#{domain_suffix}"

  def ip_v4_address = Array.new(4) { (rand(254) + 1).to_s }.join(".")
  def mac_address = Array.new(6) { format("%02x", rand(256)) }.join(":")

  def url(host = nil, path = nil, scheme = "http")
    h = host.nil? ? domain_name : host
    pa = path.nil? ? "/#{username}" : path
    "#{scheme}://#{h}#{pa}"
  end

  def password(min_length = 8) = Faker.bothify(Array.new(min_length) { rand(2) == 0 ? "?" : "#" }.join)

  def slug(words = nil, glue = nil)
    w = words.nil? ? Faker::Lorem.words(2).join(" ") : words
    g = glue.nil? ? Faker.pick(["-", "_"]) : glue
    w.gsub(" ", g).downcase
  end
end

module Faker::Lorem
  module_function

  WORDS = %w[alias consequatur aut perferendis sit voluptatem accusantium doloremque aperiam eaque ipsa quae ab illo
             inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo aspernatur odit fugit sed quia
             magni dolores eos ratione sequi nesciunt neque porro quisquam dolorem ipsum]

  def word = Faker.pick(WORDS)
  def words(number = 3) = Array.new(number) { word }
  def character = Faker.pick("abcdefghijklmnopqrstuvwxyz0123456789".chars)
  def characters(number = 255) = Array.new(number) { character }.join

  def sentence(word_count = 4, random_words_to_add = 0)
    n = word_count + rand(random_words_to_add + 1)
    words(n).join(" ").capitalize + "."
  end

  def sentences(number = 3) = Array.new(number) { sentence }

  def paragraph(sentence_count = 3, random_sentences_to_add = 0)
    n = sentence_count + rand(random_sentences_to_add + 1)
    sentences(n).join(" ")
  end

  def paragraphs(number = 3) = Array.new(number) { paragraph }
  def question(word_count = 4) = words(word_count).join(" ").capitalize + "?"
end

module Faker::Number
  module_function

  def digit = rand(10)
  def non_zero_digit = rand(9) + 1

  def number(digits = 10)
    raise ArgumentError, "digits must be positive" if digits < 1
    s = non_zero_digit.to_s
    (digits - 1).times { s += digit.to_s }
    s.to_i
  end

  def leading_zero_number(digits = 10) = Array.new(digits) { digit.to_s }.join

  def decimal(l_digits = 5, r_digits = 2)
    l = number(l_digits)
    r = r_digits > 1 ? leading_zero_number(r_digits - 1) + non_zero_digit.to_s : non_zero_digit.to_s
    "#{l}.#{r}".to_f
  end

  def between(from = 1, to = 5000) = from + rand(to - from + 1)
  def within(range) = between(range.begin, range.exclude_end? ? range.end - 1 : range.end)
  def positive(from = 1.0, to = 5000.0) = from + rand * (to - from)
  def negative(from = -5000.0, to = -1.0) = from + rand * (to - from)
  def hexadecimal(digits = 6) = Array.new(digits) { Faker.pick("0123456789abcdef".chars) }.join
  def binary(digits = 4) = Array.new(digits) { rand(2).to_s }.join
end

module Faker::Address
  module_function

  CITY_PREFIXES = %w[North East West South New Lake Port]
  CITY_SUFFIXES = %w[town ton land ville berg burgh borough bury view port mouth stad furt chester fort haven side shire]
  STREET_SUFFIXES = %w[Avenue Boulevard Court Drive Lane Parkway Place Road Street Way]
  STATES = ["Alabama", "Alaska", "Arizona", "California", "Colorado", "Florida", "Georgia", "Hawaii", "Illinois", "Kansas",
            "Maine", "Nevada", "New York", "Ohio", "Oregon", "Texas", "Utah", "Vermont", "Washington", "Wyoming"]
  STATE_ABBRS = %w[AL AK AZ CA CO FL GA HI IL KS ME NV NY OH OR TX UT VT WA WY]
  COUNTRIES = %w[Argentina Brazil Canada Denmark Egypt France Germany Hungary India Japan Kenya Mexico Norway Peru Spain Sweden Thailand Vietnam]

  def city_prefix = Faker.pick(CITY_PREFIXES)
  def city_suffix = Faker.pick(CITY_SUFFIXES)
  def street_suffix = Faker.pick(STREET_SUFFIXES)
  def state = Faker.pick(STATES)
  def state_abbr = Faker.pick(STATE_ABBRS)
  def country = Faker.pick(COUNTRIES)

  def city
    case rand(4)
    when 0 then "#{city_prefix} #{Faker::Name.first_name}#{city_suffix}"
    when 1 then "#{city_prefix} #{Faker::Name.first_name}"
    when 2 then "#{Faker::Name.first_name}#{city_suffix}"
    else "#{Faker::Name.last_name}#{city_suffix}"
    end
  end

  def street_name = rand(2) == 0 ? "#{Faker::Name.last_name} #{street_suffix}" : "#{Faker::Name.first_name} #{street_suffix}"
  def building_number = Faker.numerify(Faker.pick(["#####", "####", "###"]))
  def secondary_address = Faker.numerify(Faker.pick(["Apt. ###", "Suite ###"]))

  def street_address(include_secondary = false)
    s = "#{building_number} #{street_name}"
    include_secondary ? s + " " + secondary_address : s
  end

  def zip_code = Faker.numerify(Faker.pick(["#####", "#####-####"]))
  def zip = zip_code
  def postcode = zip_code
  def full_address = "#{street_address}, #{city}, #{state_abbr} #{zip_code}"
  def latitude = rand * 180.0 - 90.0
  def longitude = rand * 360.0 - 180.0
end

module Faker::Company
  module_function

  SUFFIXES = ["Inc", "and Sons", "LLC", "Group"]
  INDUSTRIES = ["Automotive", "Banking", "Computer Software", "Education", "Farming", "Hospitality", "Insurance",
                "Logistics", "Mining", "Publishing", "Retail", "Telecommunications"]
  BUZZWORDS = %w[adaptive innovative robust scalable seamless synergistic versatile]
  BS_VERBS = %w[implement utilize integrate streamline optimize deliver transform]
  BS_ADJECTIVES = %w[clicks-and-mortar value-added vertical proactive robust scalable]
  BS_NOUNS = %w[synergies web-readiness paradigms markets partnerships solutions]

  def suffix = Faker.pick(SUFFIXES)
  def industry = Faker.pick(INDUSTRIES)
  def buzzword = Faker.pick(BUZZWORDS)

  def name
    case rand(3)
    when 0 then "#{Faker::Name.last_name} #{suffix}"
    when 1 then "#{Faker::Name.last_name}-#{Faker::Name.last_name}"
    else "#{Faker::Name.last_name}, #{Faker::Name.last_name} and #{Faker::Name.last_name}"
    end
  end

  def bs = "#{Faker.pick(BS_VERBS)} #{Faker.pick(BS_ADJECTIVES)} #{Faker.pick(BS_NOUNS)}"
  def catch_phrase = "#{buzzword.capitalize} #{buzzword} #{Faker.pick(BS_NOUNS)}"
  def ein = Faker.numerify("##-#######")
end

module Faker::Boolean
  module_function

  def boolean(true_ratio = 0.5) = rand < true_ratio
end

module Faker::Color
  module_function

  COLOR_NAMES = %w[red green blue yellow orange purple black white gray teal]

  def color_name = Faker.pick(COLOR_NAMES)
  def hex_color = "#" + Faker::Number.hexadecimal(6)
  def rgb_color = Array.new(3) { rand(256) }
end
