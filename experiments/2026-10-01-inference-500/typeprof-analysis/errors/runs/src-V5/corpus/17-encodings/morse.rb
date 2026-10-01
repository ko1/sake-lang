# Morse code: text -> dots/dashes -> on/off keying signal, and back again.
# Unknown characters are collected; a damaged signal decodes to "?" where needed.

require "set"

MORSE_TABLE = {
  "A" => ".-", "B" => "-...", "C" => "-.-.", "D" => "-..", "E" => ".", "F" => "..-.",
  "G" => "--.", "H" => "....", "I" => "..", "J" => ".---", "K" => "-.-", "L" => ".-..",
  "M" => "--", "N" => "-.", "O" => "---", "P" => ".--.", "Q" => "--.-", "R" => ".-.",
  "S" => "...", "T" => "-", "U" => "..-", "V" => "...-", "W" => ".--", "X" => "-..-",
  "Y" => "-.--", "Z" => "--..", "0" => "-----", "1" => ".----", "2" => "..---",
  "3" => "...--", "4" => "....-", "5" => ".....", "6" => "-....", "7" => "--...",
  "8" => "---..", "9" => "----.", "." => ".-.-.-", "," => "--..--", "?" => "..--.."
}

def to_morse(text, table, unknown)
  text.upcase.split(" ").map do |word|
    word.chars.filter_map do |c|
      code = table[c]
      unknown << c if !code    
      code
    end.join(" ")
  end.join(" / ")
end

# timing: dot = 1 unit on, dash = 3 on, gap inside letter 1 off, between letters 3, words 7
def to_signal(morse)
  morse.split(" / ").map do |word|
    word.split(" ").map do |letter|
      letter.chars.map { |sym| sym == "." ? "=" : "===" }.join("_")
    end.join("___")
  end.join("_______")
end

def from_signal(signal)
  signal.scan(/=+|_+/).map do |run|
    n = run.size
    if run.start_with?("=")
      n >= 2 ? "-" : "."
    elsif n >= 6
      " / "
    elsif n >= 2
      " "
    else
      ""
    end
  end.join
end

def from_morse(morse, table)
  inverse = table.invert
  morse.split(" / ").map do |word|
    word.split(" ").map { |code| inverse[code] || "?" }.join
  end.join(" ")
end

messages = ["SOS", "Hello, World", "What hath God wrought?", "Meet at 1030 sharp", "Café #9"]
messages.each do |msg|
  unknown = Set.new
  morse = to_morse(msg, MORSE_TABLE, unknown)
  signal = to_signal(morse)
  back = from_morse(from_signal(signal), MORSE_TABLE)
  puts msg
  puts "  morse : #{morse}"
  puts "  units : #{signal.size} (#{signal.count("=")} on)"
  puts "  decode: #{back}"
  puts "  skipped: #{unknown.to_a.sort.join(" ")}" unless unknown.empty?
end

puts "signal sample: #{to_signal(to_morse("PARIS", MORSE_TABLE, Set.new))}"

# a noisy line: one dash stretched, one gap dropped, one unknown pattern
noisy = "===_===_===___=_=_=____=====_=====_=====___=_=_=_=_=_=_="
puts "noisy decode: #{from_morse(from_signal(noisy), MORSE_TABLE)}"

lengths = MORSE_TABLE.transform_values(&:size)
longest = lengths.max_by { |_, n| n }
if longest
  ch, n = longest
  puts "longest code: #{ch} (#{n} symbols)"
end
puts "letters with 4 symbols: #{lengths.select { |c, n| n == 4 && c.match?(/[A-Z]/) }.keys.sort.join}"
