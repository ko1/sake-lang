class Contact
  attr_reader :id, :name, :email, :phone, :city, :updated

  def initialize(id, name, email, phone, city, updated)
    @id = id
    @name = name
    @email = email
    @phone = phone
    @city = city
    @updated = updated
  end
end

class UnionFind
  attr_reader :parent, :size

  def initialize
    @parent = {}
    @size = {}
  end

  def find(x)
    parent[x] = x unless parent.key?(x)
    size[x] = 1 unless size.key?(x)
    root = x
    root = parent.fetch(root) while parent.fetch(root) != root
    while x != root
      nxt = parent.fetch(x)
      parent[x] = root
      x = nxt
    end
    root
  end

  def union(a, b)
    ra = find(a)
    rb = find(b)
    return ra if ra == rb
    ra, rb = rb, ra if size.fetch(ra) < size.fetch(rb)
    parent[rb] = ra
    size[ra] = size.fetch(ra) + size.fetch(rb)
    ra
  end
end

def contacts
  [
    Contact.new(1, "Maria  Lopez", "Maria.Lopez@Example.com", "(555) 010-2233", "Austin", "2025-11-02"),
    Contact.new(2, "maria lopez", "mlopez@work.example", "555.010.2233", nil, "2026-01-15"),
    Contact.new(3, "Tom O'Neil", "tom@oneil.example", "", "Boston", "2025-06-30"),
    Contact.new(4, "Thomas ONeil", "TOM@ONEIL.EXAMPLE ", "617-555-0199", "Boston", "2026-02-01"),
    Contact.new(5, "Priya Natarajan", "priya.n@example.com", "555-777-1000", "Seattle", "2025-12-12"),
    Contact.new(6, "Lee Wong", "lee@wong.example", "555-123-4567", "Denver", "2024-03-03"),
    Contact.new(7, "M. Lopez", "mlopez@work.example", "", "Austin TX", "2025-08-08"),
    Contact.new(8, "Lee  Wong", "", "+1 555 123 4567", "Denver", "2025-01-20"),
    Contact.new(9, "Ana Silva", "ana@silva.example", "555-999-0000", "Miami", "2025-05-05")
  ]
end

def norm_email(e)
  e = e.strip.downcase
  e.empty? ? nil : e
end

def norm_phone(p)
  digits = p.delete("^0-9")
  digits = digits[1..] || "" if digits.size == 11 && digits.start_with?("1")
  digits.size == 10 ? digits : nil
end

def norm_name(n) = n.downcase.delete("'.").gsub(/\s+/, " ")

def best_value(records)
  records.sort_by(&:updated).reverse.each do |c|
    v = yield(c)
    return v if v && v != ""
  end
  nil
end

people = contacts
uf = UnionFind.new
by_key = {}
people.each do |c|
  uf.find(c.id)
  keys = []
  email = norm_email(c.email)
  phone = norm_phone(c.phone)
  keys << "email:" + email if email
  keys << "phone:" + phone if phone
  keys << "name:" + norm_name(c.name)
  keys.each do |k|
    other = by_key[k]
    if other
      uf.union(other, c.id)
    else
      by_key[k] = c.id
    end
  end
end

clusters = people.group_by { |c| uf.find(c.id) }
merged = clusters.values.map do |group|
  {
    ids: group.map(&:id).sort,
    name: best_value(group, &:name),
    emails: group.filter_map { |c| norm_email(c.email) }.uniq,
    phone: best_value(group) { |c| norm_phone(c.phone) },
    city: best_value(group, &:city),
    last: group.map(&:updated).max
  }
end

def fmt_phone(p)
  return "-" if p.nil?
  "(#{p[0..2]}) #{p[3..5]}-#{p[6..]}"
end

puts "#{people.size} records -> #{merged.size} customers"
puts
merged.sort_by { |m| m[:ids].fetch(0) }.each do |m|
  ids = m[:ids]
  tag = ids.size > 1 ? "merged #{ids.join("+")}" : "single #{ids.fetch(0)}"
  puts format("%-14s %-16s %-14s %-9s %s", tag, m[:name], fmt_phone(m[:phone]), m[:city] || "-", m[:last])
  m[:emails].each { |e| puts "               <#{e}>" }
end
puts
dups = merged.count { |m| m[:ids].size > 1 }
removed = people.size - merged.size
puts format("duplicate clusters: %d, records folded: %d (%.0f%%)", dups, removed, removed * 100.0 / people.size)
no_contact = merged.select { |m| m[:emails].empty? && m[:phone].nil? }
puts "customers without email or phone: #{no_contact.size}"
