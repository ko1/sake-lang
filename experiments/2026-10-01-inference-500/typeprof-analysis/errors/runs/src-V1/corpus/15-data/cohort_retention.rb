require "set"

class User
  attr_reader :id, :signup, :plan

  def initialize(id, signup, plan)
    @id = id
    @signup = signup
    @plan = plan
  end
end

def users
  [
    User.new("u01", "2026-01-05", :free), User.new("u02", "2026-01-12", :pro),
    User.new("u03", "2026-01-20", :free), User.new("u04", "2026-01-28", :free),
    User.new("u05", "2026-02-02", :pro), User.new("u06", "2026-02-14", :free),
    User.new("u07", "2026-02-21", :team), User.new("u08", "2026-03-03", :free),
    User.new("u09", "2026-03-09", :pro), User.new("u10", "2026-03-15", :free),
    User.new("u11", "2026-03-30", :team), User.new("u12", "2026-04-04", :free)
  ]
end

def activity_log
  <<~TXT
    u01 2026-01-06 u01 2026-02-10 u01 2026-03-02 u01 2026-04-11
    u02 2026-01-13 u02 2026-02-01 u02 2026-02-20 u02 2026-03-18 u02 2026-04-02
    u03 2026-01-21
    u04 2026-02-15 u04 2026-04-20
    u05 2026-02-03 u05 2026-03-04 u05 2026-04-05
    u06 2026-02-15
    u07 2026-02-22 u07 2026-03-01 u07 2026-04-30
    u08 2026-03-04 u08 2026-04-09
    u09 2026-03-10
    u10 2026-03-16 u10 2026-03-17
    u11 2026-03-31 u11 2026-04-01
    u12 2026-04-05
    u99 2026-02-02
  TXT
end

def month_index(date)
  m = date.match(/\A(\d{4})-(\d{2})/)
  raise ArgumentError, "bad date #{date}" unless m
  m[1].to_i * 12 + m[2].to_i - 1
end

def month_label(idx) = format("%04d-%02d", idx / 12, idx % 12 + 1)

def parse_activity(text)
  active = {}
  text.split.each_slice(2) do |uid, date|
    (active[uid] ||= Set.new) << month_index(date)
  end
  active
end

def pct(n, d) = d == 0 ? "   -" : format("%3d%%", n * 100 / d)

all_users = users
active = parse_activity(activity_log)
known = all_users.map(&:id).to_set
unknown = active.keys.reject { |id| known.include?(id) }
last_month = active.values.flat_map(&:to_a).max

cohorts = all_users.group_by { |u| month_index(u.signup) }
puts "Monthly retention by signup cohort"
max_offset = 3
head = format("%-8s %5s", "cohort", "users")
0.upto(max_offset) { |k| head += format(" %5s", "M#{k}") }
puts head
cohorts.keys.sort.each do |start|
  members = cohorts.fetch(start)
  row = format("%-8s %5d", month_label(start), members.size)
  0.upto(max_offset) do |k|
    if start + k > last_month
      row += format(" %5s", "")
      next
    end
    retained = members.count { |u| active.fetch(u.id, Set.new).include?(start + k) }
    row += format(" %5s", pct(retained, members.size))
  end
  puts row
end

puts
puts "Retention after one month, by plan:"
by_plan = all_users.group_by(&:plan)
by_plan.keys.sort_by(&:to_s).each do |plan|
  members = by_plan.fetch(plan).select { |u| month_index(u.signup) + 1 <= last_month }
  kept = members.count do |u|
    months = active[u.id]
    !months.nil? && months.include?(month_index(u.signup) + 1)
  end
  puts format("  %-5s %d/%d %s", plan, kept, members.size, pct(kept, members.size))
end

puts
dormant = all_users.select do |u|
  months = active[u.id]
  months.nil? || months.max < last_month - 1
end
puts "Dormant (no activity in last 2 months): #{dormant.map(&:id).join(" ")}"
puts "Activity from unknown users: #{unknown.join(" ")}" unless unknown.empty?
