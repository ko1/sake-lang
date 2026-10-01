class Doctor
  attr_reader :name, :specialty, :days, :grid

  def initialize(name, specialty, days, grid)
    @name = name
    @specialty = specialty
    @days = days
    @grid = grid
  end
end

class Request
  attr_reader :patient, :specialty, :minutes, :prefer

  def initialize(patient, specialty, minutes, prefer)
    @patient = patient
    @specialty = specialty
    @minutes = minutes
    @prefer = prefer
  end
end

DAY_NAMES = %w[Mon Tue Wed Thu Fri]
SLOT_LEN = 15
OPENING = 9 * 60
SLOTS_PER_DAY = 32

def clock(slot)
  m = OPENING + slot * SLOT_LEN
  format("%02d:%02d", m / 60, m % 60)
end

def new_doctor(name, specialty, days)
  grid = DAY_NAMES.map { |d| days.include?(d) ? Array.new(SLOTS_PER_DAY) : nil }
  Doctor.new(name, specialty, days, grid)
end

# first run of `need` free slots on a day, within the preferred half of the day
def free_run(row, need, prefer)
  lo, hi = case prefer
           when :morning then [0, 12]
           when :afternoon then [16, SLOTS_PER_DAY]
           when :any then [0, SLOTS_PER_DAY]
           end
  start = lo
  while start + need <= hi
    blocked = (start...(start + need)).find { |i| row[i] }
    return start unless blocked
    start = blocked + 1
  end
  nil
end

def schedule(doctors, req)
  need = req.minutes.ceildiv(SLOT_LEN)
  candidates = doctors.select { |d| d.specialty == req.specialty }
  DAY_NAMES.each_with_index do |day, di|
    candidates.each do |doc|
      row = doc.grid[di]
      next unless row
      start = free_run(row, need, req.prefer)
      next unless start
      need.times { |k| row[start + k] = req.patient }
      return [doc, day, start, need]
    end
  end
  nil
end

def cancel(doctors, patient)
  freed = 0
  doctors.each do |doc|
    doc.grid.compact.each do |row|
      row.each_index do |i|
        if row[i] == patient
          row[i] = nil
          freed += 1
        end
      end
    end
  end
  freed
end

def book_and_report(doctors, req, waitlist)
  booked = schedule(doctors, req)
  if booked
    doc, day, start, need = booked
    puts format("%-6s %-11s %s %s-%s with %s", req.patient, req.specialty, day, clock(start), clock(start + need), doc.name)
  else
    puts format("%-6s %-11s no slot (%s), waitlisted", req.patient, req.specialty, req.prefer)
    waitlist << req
  end
end

doctors = [
  new_doctor("Dr. Ito", "general", %w[Mon Tue Thu]),
  new_doctor("Dr. Park", "general", %w[Wed Fri]),
  new_doctor("Dr. Rao", "dermatology", %w[Tue]),
  new_doctor("Dr. Diaz", "cardiology", %w[Mon Fri])
]

requests = [
  Request.new("amy", "general", 30, :morning),
  Request.new("bo", "dermatology", 120, :morning),
  Request.new("cal", "dermatology", 60, :morning),
  Request.new("dee", "cardiology", 90, :afternoon),
  Request.new("eli", "dermatology", 45, :afternoon),
  Request.new("fay", "general", 45, :any),
  Request.new("gus", "dermatology", 240, :afternoon),
  Request.new("hal", "dermatology", 30, :morning),
  Request.new("ivy", "orthopedics", 30, :any)
]

waitlist = []
requests.each { |r| book_and_report(doctors, r, waitlist) }

puts
puts "bo cancels: #{cancel(doctors, "bo")} slots freed"
pending = waitlist
waitlist = []
while (r = pending.shift) && r
  book_and_report(doctors, r, waitlist)
end

puts
doctors.each do |doc|
  doc.grid.each_with_index do |row, di|
    next unless row
    line = row.map { |p| p ? p[0].upcase : "." }.join
    used = row.count { |p| p }
    puts format("%-9s %s %s %3d%%", doc.name, DAY_NAMES[di], line, used * 100 / SLOTS_PER_DAY)
  end
end
puts "Still waiting: #{waitlist.map(&:patient).join(", ")}"
