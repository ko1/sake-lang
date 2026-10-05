class Ident
  attr_reader :source, :style, :words

  def initialize(source, style, words)
    @source = source
    @style = style
    @words = words
  end
end

def upper?(c) = c >= "A" && c <= "Z"
def lower?(c) = c >= "a" && c <= "z"
def digit?(c) = c >= "0" && c <= "9"

def detect_style(s)
  if s.include?("_")
    s.upcase == s ? :screaming : :snake
  elsif s.include?("-")
    :kebab
  elsif s.include?(" ")
    :words
  elsif upper?(s[0])
    :pascal
  else
    :camel
  end
end

def split_words(s)
  words = []
  current = +""
  chars = s.chars
  chars.each_with_index do |c, i|
    if c == "_" || c == "-" || c == " "
      words << current unless current.empty?
      current = +""
      next
    end
    prev = i > 0 ? chars[i - 1] : ""
    nxt = chars[i + 1]
    boundary = false
    if upper?(c) && !current.empty?
      boundary = true if lower?(prev) || digit?(prev)
      boundary = true if upper?(prev) && nxt && lower?(nxt)
    end
    boundary = true if digit?(c) && lower?(prev) && current.size > 1
    if boundary
      words << current
      current = +""
    end
    current << c
  end
  words << current unless current.empty?
  words.map(&:downcase)
end

def parse_ident(s) = Ident.new(s, detect_style(s), split_words(s))

def convert(words, style)
  case style
  when :snake then words.join("_")
  when :screaming then words.join("_").upcase
  when :kebab then words.join("-")
  when :camel then words.first + words.drop(1).map(&:capitalize).join
  when :pascal then words.map(&:capitalize).join
  when :words then words.join(" ")
  when :title then words.map { |w| small_word?(w) ? w : w.capitalize }.join(" ")
  end
end

def small_word?(w) = ["of", "the", "and", "to", "in", "a"].include?(w)

def styles = [:snake, :screaming, :kebab, :camel, :pascal, :title]

def inputs
  [
    "parseHTTPResponse", "user_id", "MAX_RETRY_COUNT", "content-type",
    "XMLHttpRequest", "base64Encode", "the lord of the rings", "OAuth2Token",
    "already_snake_case", "iPhone"
  ]
end

idents = inputs.map { |s| parse_ident(s) }
width = inputs.map(&:size).max
idents.each do |id|
  label = id.source.ljust(width)
  puts "#{label}  #{id.style}: #{id.words.join(" | ")}"
  styles.each do |st|
    out = convert(id.words, st)
    marker = st == id.style && out == id.source ? " (same)" : ""
    puts "    #{st.to_s.ljust(10)} #{out}#{marker}"
  end
end

by_style = Hash.new(0)
idents.each { |id| by_style[id.style] += 1 }
puts "styles seen:"
by_style.sort_by { |k, _| k.to_s }.each do |k, v|
  puts "  #{k}: #{v}"
end

round_trip = idents.count do |id|
  st = id.style
  st != :words && convert(id.words, st) == id.source
end
puts "round-trip exact: #{round_trip}/#{idents.size}"
