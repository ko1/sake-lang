require "set"

class Rule
  attr_reader :pattern, :replacement

  def initialize(pattern, replacement)
    @pattern = pattern
    @replacement = replacement
  end
end

def keep_case(original, word)
  return word if original.empty?
  first = original[0]
  first == first.upcase && first != first.downcase ? word.capitalize : word
end

def apply_rules(word, rules)
  rule = rules.find { |r| word.match?(r.pattern) }
  return word if rule.nil?
  word.sub(rule.pattern, rule.replacement)
end

class Inflections
  attr_reader :plurals, :singulars, :irregular, :uncountable

  def initialize(plurals, singulars, irregular, uncountable)
    @plurals = plurals
    @singulars = singulars
    @irregular = irregular
    @uncountable = uncountable
  end

  def pluralize(word)
    lower = word.downcase
    return word if uncountable.include?(lower)
    plural = irregular[lower]
    return keep_case(word, plural) if plural
    return word if irregular.value?(lower)
    apply_rules(word, plurals)
  end

  def singularize(word)
    lower = word.downcase
    return word if uncountable.include?(lower)
    single = irregular.key(lower)
    return keep_case(word, single) if single
    return word if irregular.key?(lower)
    apply_rules(word, singulars)
  end

  def count_phrase(n, word)
    noun = n == 1 ? word : pluralize(word)
    amount = n == 0 ? "no" : n.to_s
    "#{amount} #{noun}"
  end
end

def build_inflections
  plurals = [
    Rule.new(/(quiz)\z/i, "\\1zes"),
    Rule.new(/(matr|vert|ind)(?:ix|ex)\z/i, "\\1ices"),
    Rule.new(/(x|ch|ss|sh)\z/i, "\\1es"),
    Rule.new(/([^aeiouy]|qu)y\z/i, "\\1ies"),
    Rule.new(/(?:([^f])fe|([lr])f)\z/i, "\\1\\2ves"),
    Rule.new(/(buffal|tomat|potat)o\z/i, "\\1oes"),
    Rule.new(/(octop|vir)us\z/i, "\\1i"),
    Rule.new(/(alias|status|bus)\z/i, "\\1es"),
    Rule.new(/s\z/i, "s"),
    Rule.new(/\z/, "s")
  ]
  singulars = [
    Rule.new(/(quiz)zes\z/i, "\\1"),
    Rule.new(/(matr)ices\z/i, "\\1ix"),
    Rule.new(/(vert|ind)ices\z/i, "\\1ex"),
    Rule.new(/(x|ch|ss|sh)es\z/i, "\\1"),
    Rule.new(/([^aeiouy]|qu)ies\z/i, "\\1y"),
    Rule.new(/([lr])ves\z/i, "\\1f"),
    Rule.new(/([^f])ves\z/i, "\\1fe"),
    Rule.new(/(buffal|tomat|potat)oes\z/i, "\\1o"),
    Rule.new(/(octop|vir)i\z/i, "\\1us"),
    Rule.new(/(alias|status|bus)es\z/i, "\\1"),
    Rule.new(/ss\z/i, "ss"),
    Rule.new(/s\z/i, "")
  ]
  irregular = { "person" => "people", "man" => "men", "child" => "children",
                "mouse" => "mice", "goose" => "geese", "ox" => "oxen" }
  uncountable = Set["equipment", "information", "rice", "money", "species", "series", "fish", "sheep"]
  Inflections.new(plurals, singulars, irregular, uncountable)
end

def to_sentence(items)
  case items.size
  when 0 then ""
  when 1 then items[0]
  when 2 then "#{items[0]} and #{items[1]}"
  else "#{items[0...-1].join(", ")}, and #{items.last}"
  end
end

inf = build_inflections
words = ("cat box church query day knife wolf leaf tomato octopus status quiz matrix vertex " \
         "person Child mouse sheep rice bus alias Category hero").split(" ")
failures = 0
words.each do |w|
  pl = inf.pluralize(w)
  back = inf.singularize(pl)
  ok = back == w
  failures += 1 unless ok
  puts "#{w.ljust(10)} -> #{pl.ljust(12)} -> #{back.ljust(10)}#{ok ? "" : "  (round trip fails)"}"
end
puts "round-trip failures: #{failures}"
puts

inventory = [["apple", 3], ["box", 1], ["mouse", 2], ["fish", 5], ["person", 0], ["knife", 12]]
phrases = inventory.map { |name, n| inf.count_phrase(n, name) }
puts "In stock: #{to_sentence(phrases)}."
[0, 1, 2, 3].each do |k|
  puts "#{k}: #{to_sentence(["red", "green", "blue"].take(k)).inspect}"
end
