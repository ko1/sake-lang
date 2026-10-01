# Deduplicate contacts: normalize emails and phones, link records that share either (union-find), merge.

class Contact
  attr_reader :id, :name, :emails, :phones, :tags

  def initialize(id, name, emails, phones, tags)
    @id = id
    @name = name
    @emails = emails
    @phones = phones
    @tags = tags
  end
end

class UnionFind
  attr_reader :parent

  def initialize(parent)
    @parent = parent
  end

  def find(x)
    root = x
    root = @parent[root] while @parent[root] != root
    while @parent[x] != root
      nxt = @parent[x]
      @parent[x] = root
      x = nxt
    end
    root
  end

  def union(a, b)
    ra = find(a)
    rb = find(b)
    return if ra == rb
    if ra < rb
      @parent[rb] = ra
    else
      @parent[ra] = rb
    end
  end
end

def normalize_email(e)
  e = e.strip.downcase
  at = e.index("@")
  return nil unless at
  local = e[0...at].split("+")[0]
  domain = e[(at + 1)..]
  local = local.delete(".") if domain == "gmail.com"
  "#{local}@#{domain}"
end

def normalize_phone(p)
  digits = p.delete("^0-9")
  digits = digits[1..] if digits.size == 11 && digits.start_with?("1")
  digits.size == 10 ? digits : nil
end

def raw_contacts
  [
    "1|Ann Lee|ann.lee@gmail.com; ann@work.io|555-010-2000|friend",
    "2|Ann  Lee|AnnLee@Gmail.com|(555) 010 2000|",
    "3|Bob Stone|bob@stone.dev|+1 555 777 1234|work",
    "4|Robert Stone|bob+news@stone.dev|555.777.9999|work; golf",
    "5|Cy Twombly|cy@art.org|12345|",
    "6|Dee Park|dee@park.kr; d.park@mail.kr||friend",
    "7|D. Park|d.park@mail.kr|555 222 3333|family",
    "8|Eve|eve@example.com|555-222-3333|"
  ]
end

def split_list(s) = s.split(";").map(&:strip).reject(&:empty?)

def parse(line)
  f = line.split("|")
  emails = split_list(f[2]).map { |e| normalize_email(e) }.compact.to_set
  phones = split_list(f[3] || "").map { |p| normalize_phone(p) }.compact.to_set
  tags = split_list(f[4] || "").to_set
  Contact.new(f[0].to_i, f[1].squeeze(" "), emails, phones, tags)
end

contacts = raw_contacts.map { |l| parse(l) }
bad_phones = raw_contacts.select { |l| split_list(l.split("|")[3] || "").any? { |p| !normalize_phone(p)     } }
puts "unparseable phones in: #{bad_phones.map { |l| l.split("|")[0] }.join(",")}"

uf = UnionFind.new({})
contacts.each { |c| uf.parent[c.id] = c.id }
owner = {}
contacts.each do |c|
  keys = c.emails.map { |e| "e:#{e}" } + c.phones.map { |p| "p:#{p}" }
  keys.each do |k|
    prev = owner[k]
    if prev
      uf.union(prev, c.id)
    else
      owner[k] = c.id
    end
  end
end

groups = contacts.group_by { |c| uf.find(c.id) }
puts "#{contacts.size} records -> #{groups.size} people"
groups.each do |root, members|
  names = members.map(&:name).uniq
  best = names.max_by(&:size)
  emails = members.reduce(Set[]) { |acc, c| acc | c.emails }
  phones = members.reduce(Set[]) { |acc, c| acc | c.phones }
  tags = members.reduce(Set[]) { |acc, c| acc | c.tags }
  puts "#{best} [#{members.map(&:id).join(",")}]"
  puts "  aka: #{(names - [best]).sort.join("; ")}" if names.size > 1
  puts "  emails: #{emails.sort.join(", ")}"
  puts "  phones: #{phones.empty? ? "-" : phones.sort.map { |p| "#{p[0..2]}-#{p[3..5]}-#{p[6..]}" }.join(", ")}"
  puts "  tags: #{tags.sort.join(", ")}" unless tags.empty?
end
shared = contacts.flat_map { |c| c.phones.to_a }.tally.select { |p, n| n > 1 }
puts "shared phones: #{shared.keys.sort.join(", ")}"
