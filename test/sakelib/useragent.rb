require "useragent"

agents = [
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.6099.71 Safari/537.36",
  "Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Mobile Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) CriOS/119.0.6045.169 Mobile/15E148 Safari/604.1",
  "Mozilla/5.0 (X11; CrOS x86_64 14541.0.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/117.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:121.0) Gecko/20100101 Firefox/121.0",
  "Mozilla/5.0 (X11; U; Linux i686; en-US; rv:1.9.0.1) Gecko/2008070206 Firefox/3.0.1",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1",
  "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en) AppleWebKit/125.2 (KHTML, like Gecko) Safari/125.8",
  "Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; rv:11.0) like Gecko",
  "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; Trident/5.0; SLCC2)",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.102 Safari/537.36 Edge/18.19582",
  "Opera/9.80 (Windows NT 6.1; U; en) Presto/2.12.388 Version/12.16",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/106.0.0.0 Safari/537.36 OPR/92.0.0.0",
  "Opera/9.80 (J2ME/MIDP; Opera Mini/9.80 (S60; SymbOS; Opera Mobi/23.348; U; en) Presto/2.5.25 Version/10.54",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/92.0.4515.131 Safari/537.36 Vivaldi/4.1.2369.21",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 9_3 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Mobile/13E233 MicroMessenger/6.3.15 NetType/WIFI Language/zh_CN",
  "iTunes/11.1.5 (Windows; Microsoft Windows 7 x64 Business Edition Service Pack 1 (Build 7601)) AppleWebKit/537.60.15",
  "iTunes/12.0.1 (Macintosh; OS X 10.10) AppleWebKit/0600.1.25",
  "AppleCoreMedia/1.0.0.12F69 (iPhone; U; CPU OS 8_3 like Mac OS X; en_us)",
  "Lavf/55.48.100",
  "Mozilla/5.0 (PLAYSTATION 3 4.75) AppleWebKit/531.22.8 (KHTML, like Gecko)",
  "Mozilla/5.0 (PlayStation Vita 3.52) AppleWebKit/537.73 (KHTML, like Gecko) Silk/3.2",
  "Mozilla/5.0 (PlayStation 4 2.57) AppleWebKit/537.73 (KHTML, like Gecko)",
  "Podcast Addict - Dalvik/2.1.0 (Linux; U; Android 5.1; XT1093 Build/LPE23.32-21.3)",
  "NSPlayer/12.00.9600.17031 WMFSDK/12.00.9600.17031",
  "NSPlayer/4.1.0.3936",
  "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
  "Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Iron/31.0.1700.0 Chrome/31.0.1700.0 Safari/537.36",
  "curl/8.4.0",
  "",
]

# browser, version, platform, os, mobile?, bot? of each
agents.each do |s|
  ua = UserAgent.parse(s)
  puts("#{ua.browser} | #{ua.version} | #{ua.platform.inspect} | #{ua.os.inspect} | mobile=#{ua.mobile?} bot=#{ua.bot?}")
end

# the products of a user agent string, and the string rebuilt from them
chrome = UserAgent.parse(agents.fetch(0))
chrome.to_a.each do |product|
  p([product.product, product.version.to_s, product.comment])
end
puts(chrome.to_s)
p(chrome.to_h)
p(chrome.length)
p(UserAgent.parse(nil).to_s)

# method_missing in Ruby: a product by name, case-insensitively
safari_product = chrome.safari

p(safari_product.to_s)
p(chrome.respond_to?("Firefox") ? chrome.firefox : nil)

# versions compare by their numbers; a String is converted
v = UserAgent::Version.new("1.10.2")
p(v > UserAgent::Version.new("1.9"))
p(v == "1.10.2")
p(v < "1.10.2a")
p(v.to_a)
p(UserAgent::Version.new("5.0b1").to_a)
p(UserAgent::Version.new("abc") == "abc")
p(UserAgent::Version.new("abc") <=> UserAgent::Version.new("abd"))
p(UserAgent::Version.new(nil).nil?)
p(UserAgent::Version.new("") == nil)
p(UserAgent::Version.new("2"))

# user agents compare by version when the browser is the same, and are never ordered otherwise
old_chrome = UserAgent.parse(agents.fetch(1))
firefox = UserAgent.parse(agents.fetch(4))
p(old_chrome < chrome)
p(chrome > old_chrome)
p(chrome < firefox)
p(chrome > firefox)
p(chrome == firefox)

# products compare the same way
a = UserAgent.new("Foo", "1.0")
b = UserAgent.new("Foo", "2.0", "x; y")
p(a < b)
p(a < UserAgent.new("Bar", "2.0"))
p(b.to_s)
p(UserAgent.new("Foo", nil, "c").to_s)
p(UserAgent.new("Foo").to_s)

# a product is required
begin
  UserAgent.new(nil)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# Internet Explorer: the Trident engine tells the real version (compatibility view)
ie7 = UserAgent.parse(agents.fetch(9))

p(ie7.trident_version)
p(ie7.real_version)
p(ie7.compatibility_view?)
p(ie7.chromeframe)
cf = UserAgent.parse("Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; chromeframe/11.0.660.0)")

cf_product = cf.chromeframe

p(cf_product.to_s)

# Webkit's build, Gecko's security and localization
safari = UserAgent.parse(agents.fetch(7))

p(safari.build)
p(safari.security)
old_firefox = UserAgent.parse(agents.fetch(5))

p(old_firefox.security)
p(old_firefox.localization)

# Windows Media Player and Podcast Addict details
wmp = UserAgent.parse(agents.fetch(24))

p(wmp.has_wmfsdk?("12"))
p(wmp.has_wmfsdk?("11"))
p(wmp.classic?)
pa = UserAgent.parse(agents.fetch(23))

p(pa.device)
p(pa.device_build)
p(pa.security)

# a comment in quotes and a gzip(gfe) suffix
p(UserAgent.parse("\"Mozilla/5.0 (X11; Linux x86_64)\"").os)
p(UserAgent.parse("Foo/1.0,gzip(gfe)").to_s)
