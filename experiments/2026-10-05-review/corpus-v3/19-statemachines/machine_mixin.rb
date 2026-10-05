module StateMachine
  def can?(event) = transitions.key?([state, event])

  def fire(event)
    target = transitions[[state, event]]
    if target.nil?
      log << "#{label}: ignored #{event} in #{state}"
      return false
    end
    before = state
    @state = target
    on_enter(target)
    log << "#{label}: #{before} --#{event}--> #{target}"
    true
  end

  def events_available
    transitions.keys.filter_map { |s, e| s == state ? e : nil }.sort_by(&:to_s)
  end
end

class Door
  include StateMachine
  attr_reader :name, :state, :log, :opened

  def initialize(name)
    @name = name
    @state = :closed
    @log = []
    @opened = 0
  end

  def label = "door #{@name}"
  def transitions = { [:closed, :open] => :opened, [:opened, :close] => :closed, [:closed, :lock] => :locked, [:locked, :unlock] => :closed }

  def on_enter(st)
    @opened += 1 if st == :opened
  end
end

class Light
  include StateMachine
  attr_reader :room, :state, :log, :brightness

  def initialize(room)
    @room = room
    @state = :off
    @log = []
    @brightness = 0
  end

  def label = "light #{@room}"
  def transitions = { [:off, :toggle] => :on, [:on, :toggle] => :off, [:on, :dim] => :dimmed, [:dimmed, :toggle] => :off, [:dimmed, :dim] => :dimmed }

  def on_enter(st)
    case st
    in :on then @brightness = 100
    in :off then @brightness = 0
    in :dimmed then @brightness = @brightness / 2
    end
  end
end

class Ticket
  include StateMachine
  attr_reader :id, :state, :log, :reopen_count

  def initialize(id)
    @id = id
    @state = :open
    @log = []
    @reopen_count = 0
  end

  def label = "ticket ##{@id}"

  def transitions
    {
      [:open, :start] => :in_progress, [:in_progress, :review] => :in_review,
      [:in_review, :approve] => :done, [:in_review, :reject] => :in_progress,
      [:done, :reopen] => :open, [:open, :close] => :done
    }
  end

  def on_enter(st)
    @reopen_count += 1 if st == :open
  end
end

front = Door.new("front")
hall = Light.new("hall")
bug = Ticket.new(42)

script = [
  [front, :open], [hall, :toggle], [hall, :dim], [front, :lock], [front, :close],
  [hall, :dim], [bug, :start], [bug, :review], [bug, :reject], [front, :lock],
  [bug, :review], [front, :unlock], [bug, :approve], [hall, :toggle], [bug, :reopen],
  [front, :open], [hall, :dim], [bug, :close]
]
fired = 0
script.each do |machine, event|
  fired += 1 if machine.fire(event)
end
puts "#{fired} of #{script.size} events fired"

front.log.each { puts it }
hall.log.each { puts it }
bug.log.each { puts it }

puts "door opened #{front.opened} times, now #{front.state}; next: #{front.events_available}"
puts "light at #{hall.brightness}%, now #{hall.state}; next: #{hall.events_available}"
puts "ticket reopened #{bug.reopen_count} times, now #{bug.state}; can reopen? #{bug.can?(:reopen)}"
