require "ipaddr"

def try(label)
  puts "#{label} => #{yield}"
rescue IPAddr::InvalidPrefixError => e
  puts "#{label} => InvalidPrefixError: #{e.message}"
rescue IPAddr::InvalidAddressError => e
  puts "#{label} => InvalidAddressError: #{e.message}"
rescue IPAddr::AddressFamilyError => e
  puts "#{label} => AddressFamilyError: #{e.message}"
end

puts "-- parsing and printing"
[
  "192.168.1.10", "192.168.1.0/24", "10.0.0.1/255.0.0.0", "0.0.0.0/0", "::", "::1", "1::",
  "2001:db8::1", "2001:0db8:0000:0000:0000:ff00:0042:8329", "fe80::1%eth0", "[::1]", "::ffff:192.168.0.1",
  "::192.168.0.1", "1:2:3:4:5:6:1.2.3.4", "2001:db8::/32", "2001:db8::1/64", "1:0:0:2::3", "1:0:0:2:0:0:0:3",
  "256.1.1.1", "01.2.3.4", "1.2.3", "1:2:3:4:5:6:7:8:9", "::1::", "garbage", "192.168.1.0/33",
  "192.168.1.0/024", "192.168.1.0/255.0.255.0", "192.168.1.0/ffff::", "2001:db8::/129", ""
].each do |s|
  try(s.inspect) do
    ip = IPAddr.new(s)
    "#{ip.to_s} | #{ip.to_string} | #{ip.inspect} | #{ip.prefix} #{ip.ipv4?} #{ip.ipv6?} #{ip.family}"
  end
end
p IPAddr.new
try("Integer AF_INET") { (IPAddr.new(3232235777, Socket::AF_INET)).to_s }
try("Integer AF_INET6") { (IPAddr.new(1, Socket::AF_INET6)).to_s }
try("Integer no family") { IPAddr.new(1) }
try("Integer bad family") { IPAddr.new(1, 99) }
try("too big") { IPAddr.new(2 ** 32, Socket::AF_INET) }
try("family mismatch") { IPAddr.new("::1", Socket::AF_INET) }
try("v4 as v6") { IPAddr.new("1.2.3.4", Socket::AF_INET6) }

puts "-- conversions"
v4 = IPAddr.new("192.168.2.130/26")
v6 = IPAddr.new("2001:db8:85a3::8a2e:370:7334/48")
[v4, v6].each do |ip|
  p ip.to_i
  p ip.cidr
  p ip.netmask
  p ip.wildcard_mask
  p ip.hton
  p IPAddr.new_ntoh(ip.hton)
  p ip.reverse
  p ip.as_json
  p ip.to_json
  first, last = ip.to_range.then { |r| [r.begin, r.end] }  # a Range in Ruby, a [first, last] Tuple in Sake
  puts "#{first.to_s}..#{last.to_s}"
  p ip.succ
end
p IPAddr.new("1.2.3.4").as_json
p IPAddr.ntop("\x7f\x00\x00\x01".b)
try("ntop 3 bytes") { IPAddr.ntop("abc".b) }
try("ntop utf-8") { IPAddr.ntop("abcd") }
p IPAddr.new("2001:db8::1").ip6_arpa
p IPAddr.new("::1").ip6_int
try("ip6_arpa v4") { v4.ip6_arpa }
p IPAddr.new("192.168.1.1").ipv4_mapped
p IPAddr.new("192.168.1.1").ipv4_compat
p IPAddr.new("::ffff:10.1.2.3").native
p IPAddr.new("::10.1.2.3").native
p IPAddr.new("::1").native
try("ipv4_mapped v6") { v6.ipv4_mapped }
p IPAddr.new("::ffff:1.2.3.4").ipv4_mapped?
p IPAddr.new("::1.2.3.4").ipv4_compat?
p IPAddr.new("::1").ipv4_compat?

puts "-- masks and operators"
ip = IPAddr.new("192.168.1.77")
p ip.mask(24)
p ip.mask("16")
p ip.mask("255.255.255.240")
try("mask 40") { ip.mask(40) }
try("mask v6") { ip.mask("ffff::") }
p ip
ip.prefix = 28
p ip
p ip.prefix
p ip & "255.255.0.0"
p ip | 0xff
p ~IPAddr.new("0.0.255.255")
p IPAddr.new("1.2.3.4") << 8
p IPAddr.new("1.2.3.4") >> 8
p IPAddr.new("1.2.3.4") + 300
p IPAddr.new("1.2.3.4") - 4
try("- too far") { IPAddr.new("0.0.0.1") - 2 }
p ~IPAddr.new("::")

puts "-- comparison"
net = IPAddr.new("192.168.1.0/24")
p net.include?(IPAddr.new("192.168.1.200"))
p net.include?("192.168.2.1")
p net.include?(IPAddr.new("192.168.1.0/25"))
p net.include?(IPAddr.new("192.168.0.0/16"))
p net.include?(IPAddr.new("::1"))
p net.===("192.168.1.9")
p IPAddr.new("1.2.3.4") == "1.2.3.4"
p IPAddr.new("1.2.3.4") == IPAddr.new("1.2.3.4/8")
p IPAddr.new("1.0.0.0/8") == IPAddr.new("1.2.3.4/8")
p IPAddr.new("1.2.3.4") == "nonsense"
p IPAddr.new("::1") == IPAddr.new("0.0.0.1")
p IPAddr.new("1.2.3.4") <=> IPAddr.new("1.2.3.5")
p IPAddr.new("1.2.3.4") <=> IPAddr.new("::1")
p IPAddr.new("1.2.3.4") <=> "junk"
p IPAddr.new("10.0.0.1") < IPAddr.new("9.0.0.1")
sorted = [IPAddr.new("10.0.0.2"), IPAddr.new("9.255.0.1"), IPAddr.new("10.0.0.1")].sort
p sorted.map { |x| x.to_s }
p sorted.max

puts "-- predicates"
["127.0.0.1", "10.1.1.1", "172.16.5.4", "172.32.0.1", "192.168.0.1", "169.254.1.1",
                 "8.8.8.8", "::1", "fc00::1", "fe80::abcd", "::ffff:127.0.0.1", "::ffff:10.0.0.1",
                 "::ffff:169.254.0.9", "2001:db8::1"].each do |s|
  ip = IPAddr.new(s)
  puts "#{s}: loopback=#{ip.loopback?} private=#{ip.private?} link_local=#{ip.link_local?}"
end

puts "-- zone id"
z = IPAddr.new("fe80::1%eth0")
p z.zone_id
p z.to_s
z.zone_id = "%lo"
p z.to_string
z.zone_id = nil
p z
try("bad zone") { z.zone_id = "eth0" }
try("zone of v4") { v4.zone_id }
