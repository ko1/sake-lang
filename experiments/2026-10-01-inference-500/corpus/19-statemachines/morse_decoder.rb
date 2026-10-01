MORSE_TABLE = {
  "A" => ".-", "B" => "-...", "C" => "-.-.", "D" => "-..", "E" => ".", "F" => "..-.",
  "G" => "--.", "H" => "....", "I" => "..", "J" => ".---", "K" => "-.-", "L" => ".-..",
  "M" => "--", "N" => "-.", "O" => "---", "P" => ".--.", "Q" => "--.-", "R" => ".-.",
  "S" => "...", "T" => "-", "U" => "..-", "V" => "...-", "W" => ".--", "X" => "-..-",
  "Y" => "-.--", "Z" => "--..", "0" => "-----", "1" => ".----", "2" => "..---", "3" => "...--"
}

# Encode text as [on?, duration] pulses, with deterministic timing jitter.
def encode(text, unit)
  pulses = []
  jitter = [0, 1, -1, 1, 0, -1]
  k = 0
  text.upcase.split(" ").each_with_index do |word, wi|
    pulses << [false, 7 * unit + jitter[k % 6]] if wi > 0
    word.chars.each_with_index do |ch, ci|
      pulses << [false, 3 * unit + jitter[k % 6]] if ci > 0
      code = MORSE_TABLE.fetch(ch, "........")
      code.chars.each_with_index do |sym, si|
        pulses << [false, unit + jitter[(k + 3) % 6]] if si > 0
        pulses << [true, (sym == "." ? unit : 3 * unit) + jitter[k % 6]]
        k += 1
      end
    end
  end
  pulses
end

def decode(pulses)
  on_lengths = pulses.select { |on, d| on }.map { |on, d| d }
  threshold = (on_lengths.min + on_lengths.max) / 2.0
  dots = on_lengths.select { it < threshold }
  unit = dots.sum / dots.size.to_f
  reverse = MORSE_TABLE.invert
  state = :between_symbols
  symbol = +""
  text = +""
  unknown = 0
  flush = 0
  pulses.each do |on, d|
    if on
      symbol << (d < threshold ? "." : "-")
      state = :in_letter
      next
    end
    ratio = d / unit
    next if ratio < 2.0 || state != :in_letter
    letter = reverse[symbol]
    if letter
      text << letter
    else
      text << "?"
      unknown += 1
    end
    symbol = +""
    flush += 1
    text << " " if ratio >= 5.0
    state = ratio >= 5.0 ? :between_words : :between_letters
  end
  unless symbol.empty?
    letter = reverse[symbol]
    text << (letter || "?")
    unknown += 1 if letter.nil?
  end
  { text: text, unit: unit, unknown: unknown, letters: flush + 1 }
end

[["sos help!", 3], ["state machine 2", 4], ["hello world", 6], ["c3po x", 5]].each do |msg, unit|
  pulses = encode(msg, unit)
  r = decode(pulses)
  r => { text:, unit: guessed, unknown:, letters: }
  ons = pulses.count { |on, d| on }
  total = pulses.sum { |on, d| d }
  puts format("%-16s unit=%d guessed=%.2f pulses=%3d on=%3d time=%4d", msg.inspect, unit, guessed, pulses.size, ons, total)
  puts format("  decoded %-16s letters=%d unknown=%d %s", text.inspect, letters, unknown, text == msg.upcase ? "OK" : "MISMATCH")
end
