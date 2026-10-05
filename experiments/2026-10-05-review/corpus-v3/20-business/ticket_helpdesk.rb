class InvalidTransition < StandardError
  attr_reader :from, :to

  def initialize(message, from, to)
    super(message)
    @from = from
    @to = to
  end
end

TRANSITIONS = {
  new: Set[:assigned, :closed],
  assigned: Set[:in_progress, :waiting, :closed],
  in_progress: Set[:waiting, :resolved],
  waiting: Set[:in_progress, :closed],
  resolved: Set[:closed, :in_progress],
  closed: Set[]
}

# minutes allowed until the first reply, and until resolution
SLA = { urgent: [30, 240], high: [120, 1440], normal: [480, 4320] }

def stamp(min) = format("d%d %02d:%02d", min / 1440 + 1, min % 1440 / 60, min % 60)

class Ticket
  attr_reader :id, :subject, :priority, :status, :opened_at, :first_reply_at, :closed_at, :log
  attr_accessor :agent

  def initialize(id, subject, priority, opened_at)
    @id = id
    @subject = subject
    @priority = priority
    @status = :new
    @agent = nil
    @opened_at = opened_at
    @first_reply_at = nil
    @closed_at = nil
    @log = []
  end

  def move(to, at)
    from = @status
    raise InvalidTransition.new("##{@id} cannot go from #{from} to #{to}", from, to) unless TRANSITIONS.fetch(from).include?(to)
    @status = to
    @first_reply_at ||= at if to == :in_progress || to == :waiting
    @closed_at = at if to == :resolved
    @log << "#{stamp(at)} #{from} -> #{to}"
  end

  def breaches(now)
    reply_limit, resolve_limit = SLA.fetch(@priority)
    out = []
    reply = @first_reply_at || now
    done = @closed_at || now
    out << "reply #{reply - @opened_at - reply_limit}m late" if reply - @opened_at > reply_limit
    out << "resolution #{done - @opened_at - resolve_limit}m late" if done - @opened_at > resolve_limit
    out
  end
end

class Desk
  attr_reader :tickets, :agents

  def initialize(agents)
    @tickets = {}
    @agents = agents
  end

  def open_ticket(id, subject, priority, at)
    @tickets[id] = Ticket.new(id, subject, priority, at)
  end

  # the agent with the fewest active tickets; ties go to the earlier name in the list
  def assign(t, at)
    load = @agents.to_h { |a| [a, 0] }
    @tickets.each_value do |x|
      load[x.agent] += 1 if x.agent && [:assigned, :in_progress, :waiting].include?(x.status)
    end
    agent = @agents.min_by { |a| [load[a], @agents.index(a)] }
    t.agent = agent
    t.move(:assigned, at)
    agent
  end
end

desk = Desk.new(["ana", "raj", "li"])
script = [
  [0, 1, :open, "VPN down for sales team", :urgent],
  [5, 2, :open, "Invoice PDF has wrong address", :normal],
  [9, 1, :assign, nil, nil],
  [12, 3, :open, "Password reset loop", :high],
  [14, 2, :assign, nil, nil],
  [20, 3, :assign, nil, nil],
  [50, 1, :to, nil, :in_progress],
  [200, 3, :to, nil, :resolved],
  [210, 3, :to, nil, :in_progress],
  [300, 1, :to, nil, :resolved],
  [320, 4, :open, "New laptop request", :normal],
  [330, 4, :assign, nil, nil],
  [400, 2, :to, nil, :waiting],
  [900, 2, :to, nil, :in_progress],
  [1000, 1, :to, nil, :closed],
  [1500, 3, :to, nil, :resolved],
  [1510, 4, :to, nil, :closed],
  [1600, 2, :to, nil, :closed],
  [1700, 5, :open, "Printer jam on 3rd floor", :high]
]

script.each do |at, id, action, subject, arg|
  case action
  when :open
    desk.open_ticket(id, subject, arg, at)
    puts "#{stamp(at)} ##{id} opened (#{arg}): #{subject}"
  when :assign
    agent = desk.assign(desk.tickets.fetch(id), at)
    puts "#{stamp(at)} ##{id} -> #{agent}"
  when :to
    desk.tickets.fetch(id).move(arg, at)
  end
rescue InvalidTransition => e
  puts "#{stamp(at)} rejected: #{e.message}"
end

now = 2000
puts
puts "Tickets at #{stamp(now)}:"
desk.tickets.each_value do |t|
  b = t.breaches(now)
  flag = b.empty? ? "ok" : "BREACH " + b.join(", ")
  puts format("  #%d %-30s %-7s %-12s %-4s %s", t.id, t.subject, t.priority, t.status, t.agent || "-", flag)
  t.log.each { |l| puts "      #{l}" }
end

resolved = desk.tickets.values.select(&:closed_at)
times = resolved.map { |t| t.closed_at - t.opened_at }.sort
puts
puts "Resolved: #{times.size}, fastest #{times.first}m, slowest #{times.last}m"
desk.tickets.values.select(&:agent).group_by(&:agent).each do |a, ts|
  puts "  #{a}: #{ts.map { |t| "##{t.id}" }.join(" ")}"
end
