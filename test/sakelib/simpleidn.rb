require "simpleidn"

# to_ascii and back (the gem's examples and RFC 3492 7.1 samples)
domains = [
  "møllerriis.com",
  "räksmörgås.josefsson.org",
  "例え.テスト",
  "mañana.com",
  "ドメイン名例.jp",
  "Bücher.example",
  "faß.de",
  "παράδειγμα.δοκιμή",
  "пример.испытание",
  "example.com",
  "MixedCase.COM",
  "",
  "...",
  ".leading.dot",
  "trailing.dot.",
  "a。b．c｡d",
]
domains.each do |domain|
  ascii = SimpleIDN.to_ascii(domain)
  puts "#{domain.inspect} -> #{ascii.inspect} -> #{SimpleIDN.to_unicode(ascii).inspect}"
end

# transitional processing maps ß, ς and the joiners
p SimpleIDN.to_ascii("faß.de", true)
p SimpleIDN.to_ascii("βόλος.com", true)
p SimpleIDN.to_ascii("βόλος.com")
p SimpleIDN.to_unicode("xn--fa-hia.de")

# the UTS #46 mapping: full-width letters, compatibility forms, deletions (soft hyphen)
p SimpleIDN.uts46map("ＡＢＣ")
p SimpleIDN.uts46map("ﬁ①Ⅻ")
p SimpleIDN.uts46map("soft­hyphen")
p SimpleIDN.uts46map("Straße", true)

# nil passes through
p SimpleIDN.to_ascii(nil)
p SimpleIDN.to_unicode(nil)

# Punycode itself (RFC 3492 7.1)
samples = [
  "ليهمابتكلموشعربي؟",
  "他们为什么不说中文",
  "Pročprostěnemluvíčesky",
  "なぜみんな日本語を話してくれないのか",
  "3年B組金八先生",
  "安室奈美恵-with-SUPER-MONKEYS",
  "Hello-Another-Way-それぞれの場所",
  "abc",
  "",
]
samples.each do |s|
  encoded = SimpleIDN::Punycode.encode(s)
  puts "#{encoded} #{SimpleIDN::Punycode.decode(encoded) == s}"
end
p SimpleIDN::Punycode.encode_digit(0)
p SimpleIDN::Punycode.encode_digit(35)
p SimpleIDN::Punycode.decode_digit("z".ord)
p SimpleIDN::Punycode.decode_digit("!".ord)
p SimpleIDN::Punycode.adapt(100, 2, true)

# malformed Punycode raises ConversionError
["ü-abc", "abc-9", "99999999999", "xn--a-ecp.ru"].each do |bad|
  begin
    p SimpleIDN::Punycode.decode(bad)
  rescue SimpleIDN::ConversionError => e
    puts "error: #{e.message}"
  end
end
begin
  SimpleIDN.to_unicode("xn--abc-9.com")
rescue SimpleIDN::ConversionError => e
  puts "error: #{e.message}"
end
