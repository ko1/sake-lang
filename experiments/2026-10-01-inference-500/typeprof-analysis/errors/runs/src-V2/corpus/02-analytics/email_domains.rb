require "set"

class Address
  attr_reader :user, :domain

  def initialize(user, domain)
    @user = user
    @domain = domain
  end

  def to_s = "#{@user}@#{@domain}"
  def tld = @domain.split(".").last

  def base_domain
    parts = @domain.split(".")
    keep = ["co", "ac"].include?(parts[-2]) ? 3 : 2
    keep = parts.size if keep > parts.size
    parts.drop(parts.size - keep).join(".")
  end
end

class InvalidAddress < StandardError
  attr_reader :raw

  def initialize(message, raw)
    super(message)
    @raw = raw
  end
end

def inbox_text
  "From: Alice <alice@example.com>, cc bob.smith@Example.com and carol@mail.example.org.
Please reply to support@shop.co.uk or sales@shop.co.uk; also ALICE@EXAMPLE.COM again.
Dave (dave@gmail.com) forwarded this to erin@gmail.com, frank@yahoo.com and dave@gmail.com.
Broken ones: grace@localhost, @nouser.com, heidi@@double.com, ivan@example..com
Newsletter: news-letter+weekly@lists.example.org, judy_99@uni.edu"
end

def candidates(text) = text.scan(/[\w.+@-]*@[\w.@-]*/)

def parse_address(raw)
  m = raw.match(/\A(?<user>[\w.+-]+)@(?<domain>[a-z0-9-]+(?:\.[a-z0-9-]+)+)\z/i)
  raise InvalidAddress.new("not an address", raw) unless m
  Address.new(m["user"].downcase, m["domain"].downcase)
end

def clean(raw) = raw.sub(/[.,;)]+\z/, "")

valid = []
invalid = []
seen = Set[]
dupes = 0
candidates(inbox_text).each do |raw|
  begin
    addr = parse_address(clean(raw))
    key = addr.to_s
    if seen.include?(key)
      dupes += 1
    else
      seen << key
      valid << addr
    end
  rescue InvalidAddress => e
    invalid << e.raw
  end
end
puts "found #{valid.size} unique addresses, #{dupes} duplicates, #{invalid.size} invalid"
puts "invalid: #{invalid.join(" ")}"

by_domain = valid.group_by(&:domain)
puts "by domain:"
by_domain.keys.sort.each do |d|
  users = by_domain[d].map(&:user).sort
  puts format("  %-20s %d  %s", d, users.size, users.join(", "))
end

tlds = Hash.new(0)
valid.each { |a| tlds[a.tld] += 1 }
puts "tlds: " + tlds.keys.sort.map { |t| "#{t}=#{tlds[t]}" }.join(" ")

orgs = Hash.new(0)
valid.each { |a| orgs[a.base_domain] += 1 }
top = orgs.max_by { |_, n| n }
if top
  d, n = top
  puts "busiest organisation: #{d} (#{n} addresses)"
end
roles = valid.select { |a| ["support", "sales", "info", "admin"].include?(a.user) }
puts "role accounts: #{roles.map(&:to_s).join(", ")}"
tagged = valid.select { |a| a.user.include?("+") }
tagged.each do |a|
  base, _, tag = a.user.partition("+")
  puts "plus-address: #{base} tagged '#{tag}' at #{a.domain}"
end
redacted = inbox_text.lines[0].gsub(/(\w)[\w.+-]*@/, "\\1***@")
puts "redacted: #{redacted.chomp}"
