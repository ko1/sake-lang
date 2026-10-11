require "unicode/display_width"

# East Asian Width: narrow, wide, ambiguous
p(Unicode::DisplayWidth.of("hello"))
p(Unicode::DisplayWidth.of("日本語"))
p(Unicode::DisplayWidth.of("ｈｅｌｌｏ"))
p(Unicode::DisplayWidth.of("ﾊﾝｶｸ"))
p(Unicode::DisplayWidth.of("한국어"))
p(Unicode::DisplayWidth.of("Ελληνικά, кириллица"))
p(Unicode::DisplayWidth.of("·"), Unicode::DisplayWidth.of("·", 2))
p(Unicode::DisplayWidth.of("○△□"), Unicode::DisplayWidth.of("○△□", 2))
p(Unicode::DisplayWidth.of("¡"), Unicode::DisplayWidth.of("¡", 2))
p(Unicode::DisplayWidth.of("café"), Unicode::DisplayWidth.of("café"))
p(Unicode::DisplayWidth.of(""))

# zero-width and control characters
p(Unicode::DisplayWidth.of("a​b"), Unicode::DisplayWidth.of("a­b"), Unicode::DisplayWidth.of(" "))
p(Unicode::DisplayWidth.of("a\tb"), Unicode::DisplayWidth.of("a\nb"), Unicode::DisplayWidth.of("ab\b"), Unicode::DisplayWidth.of("\b\b"))
p(Unicode::DisplayWidth.of("\0x\x05"), Unicode::DisplayWidth.of("\u0001\u007F"))
p(Unicode::DisplayWidth.of("กั"), Unicode::DisplayWidth.of("ᅠᆨ"))
p(Unicode::DisplayWidth.of("\u{E0001}"), Unicode::DisplayWidth.of("\u{FE0F}"), Unicode::DisplayWidth.of("\u{10FFFF}"))
p(Unicode::DisplayWidth.of("　"), Unicode::DisplayWidth.of("\u{20000}"), Unicode::DisplayWidth.of("\u{1F600}"))
p(Unicode::DisplayWidth.of("⸺"), Unicode::DisplayWidth.of("⸻"), Unicode::DisplayWidth.of("က"))

# emoji: sequences, modifiers, VS16, keycaps, flags, by mode
["🤾🏽‍♀️", "👨‍👩‍👧", "👍🏽", "❤️", "❤", "1️⃣", "🇯🇵", "☀️", "#️⃣", "🏳️‍🌈", "a👍b"].each do |e|
  widths = [false, :all, :all_no_vs16, :vs16, :rgi, :rgi_at, :possible, :none].map do |mode|
    Unicode::DisplayWidth.of(e, 1, {}, emoji: mode)
  end
  puts("#{e} #{widths.join(" ")}")
end

# overwrite: width per codepoint
p(Unicode::DisplayWidth.of("a█b", 1, {}, overwrite: {0x2588 => 2}))
p(Unicode::DisplayWidth.of("日本", 1, {}, overwrite: {"日".ord => 5}))
p(Unicode::DisplayWidth.of("xyz", 1, {}, overwrite: {"x".ord => 0, "y".ord => 3}))

# an instance with its own defaults
dw = Unicode::DisplayWidth.new(ambiguous: 2, emoji: :all)
p(dw.of("·"), dw.of("❤️"), dw.of("·", ambiguous: 1), dw.of("❤️", emoji: :none))
dw1 = Unicode::DisplayWidth.new
p(dw1.of("·日本"), dw1.of("a", overwrite: {"a".ord => 4}))

# errors
begin
  Unicode::DisplayWidth.of("x", 3)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# constants and the terminal guess
p(Unicode::DisplayWidth::VERSION, Unicode::DisplayWidth::UNICODE_VERSION, Unicode::DisplayWidth::DEFAULT_AMBIGUOUS)
p(Unicode::DisplayWidth::EmojiSupport.recommended)

# a table aligned by display width
rows = [["名前", "Name"], ["東京", "Tokyo"], ["München", "Munich"], ["😀", "smile"]]
rows.each do |a, b|
  pad = 10 - Unicode::DisplayWidth.of(a, 1, {}, emoji: :all)
  puts("|#{a}#{" " * pad}|#{b}")
end
