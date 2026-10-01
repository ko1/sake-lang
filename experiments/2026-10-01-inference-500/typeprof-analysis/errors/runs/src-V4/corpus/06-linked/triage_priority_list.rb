class Patient
  include Comparable
  attr_accessor :name, :severity, :arrival, :complaint

  def initialize(name, severity, arrival, complaint)
    @name = name
    @severity = severity
    @arrival = arrival
    @complaint = complaint
  end

  def <=>(other)
    by_sev = other.severity <=> @severity
    by_sev == 0 ? @arrival <=> other.arrival : by_sev
  end

  def to_s = "#{@name}(sev #{@severity}, t#{@arrival})"
end

class Slot
  attr_accessor :patient, :next

  def initialize(patient, nxt)
    @patient = patient
    @next = nxt
  end
end

class UnknownPatient < StandardError
  attr_reader :name

  def initialize(message, name)
    super(message)
    @name = name
  end
end

class WaitList
  attr_reader :count

  def initialize
    @first = nil
    @count = 0
  end

  def add(patient)
    slot = Slot.new(patient, nil)
    if !@first     || patient < @first.patient
      slot.next = @first
      @first = slot
    else
      cur = @first
      cur = cur.next while cur.next && cur.next.patient <= patient
      slot.next = cur.next
      cur.next = slot
    end
    @count += 1
    self
  end

  def take
    head = @first
    return nil unless head
    @first = head.next
    @count -= 1
    head.patient
  end

  def remove_named(name)
    prev = nil
    cur = @first
    while cur
      if cur.patient.name == name
        prev ? prev.next = cur.next : @first = cur.next
        @count -= 1
        return cur.patient
      end
      prev = cur
      cur = cur.next
    end
    raise UnknownPatient.new("no patient named #{name}", name)
  end

  def escalate(name, severity)
    pt = remove_named(name)
    pt.severity = severity
    add(pt)
    pt
  end

  def names
    out = []
    cur = @first
    while cur
      out << cur.patient.name
      cur = cur.next
    end
    out
  end
end

events = [
  "0 arrive Ann 2 sprained ankle",
  "1 arrive Ben 4 chest pain",
  "2 arrive Cat 2 fever",
  "3 arrive Dov 5 not breathing",
  "4 treat",
  "5 arrive Eli 3 deep cut",
  "6 escalate Cat 4",
  "7 treat",
  "8 arrive Fay 1 cough",
  "9 leave Ann",
  "10 leave Zed",
  "11 treat",
  "12 treat",
  "13 arrive Gus 3 burn",
  "14 treat",
  "15 treat",
  "16 treat"
]

wl = WaitList.new
waits = []
arrived_at = {}
events.each do |line|
  words = line.split(" ")
  t = words[0].to_i
  begin
    case words[1]
    when "arrive"
      pt = Patient.new(words[2], words[3].to_i, t, words.drop(4).join(" "))
      wl.add(pt)
      arrived_at[words[2]] = t
      puts "t=#{t} arrive #{pt} for #{pt.complaint}"
    when "treat"
      if (pt = wl.take)
        wait = t - arrived_at[pt.name]
        waits << wait
        puts "t=#{t} treat  #{pt} waited #{wait}"
      else
        puts "t=#{t} treat  nobody waiting"
      end
    when "escalate"
      pt = wl.escalate(words[2], words[3].to_i)
      puts "t=#{t} escal. #{pt}"
    when "leave"
      pt = wl.remove_named(words[2])
      puts "t=#{t} leave  #{pt}"
    end
  rescue UnknownPatient => e
    puts "t=#{t} error  #{e.message}"
  end
  puts "       queue: #{wl.names.join(", ")}" if wl.count > 0
end
puts format("treated %d, mean wait %.2f, longest %d", waits.size, waits.sum / waits.size.to_f, waits.max)
