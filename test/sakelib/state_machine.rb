require_relative "ref/state_machine"

class Job
  include AASM
  attr_reader :name, :log
  attr_accessor :ready

  def initialize(name)
    @name = name
    @ready = false
    @log = []
  end

  def aasm
    @@machine ||= AASMMachine.new(:sleeping).tap do |m|
      m.state(:running, enter: :start_clock, exit: :stop_clock)
      m.state(:cleaning)
      m.state(:failed)
      m.event(:run, from: :sleeping, to: :running, guard: :ready?)
      m.event(:clean, from: :running, to: :cleaning, after: :notify)
      m.event(:sleep, from: [:running, :cleaning], to: :sleeping)
      m.event(:fail, from: [:sleeping, :running, :cleaning], to: :failed, after: :alert)
    end
  end

  def ready? = @ready
  def start_clock = record(:start_clock)
  def stop_clock = record(:stop_clock)
  def notify = record(:notify)
  def alert
    record(:alert)
    puts "  callback alert in #{current_state}"
  end

  private

  def record(name) = @log << "#{name} (#{current_state})"
end

class TrafficLight
  include AASM
  def aasm
    @@machine ||= AASMMachine.new(:green).tap do |m|
      m.state(:yellow)
      m.state(:red)
      m.event(:next, from: :green, to: :yellow)
      m.event(:next, from: :yellow, to: :red)
      m.event(:next, from: :red, to: :green)
    end
  end
end

j = Job.new("backup")
p j.current_state
p j.states
p j.events
p j.permitted_events
p j.may_fire_event?(:run)
p j.fire(:run)
begin
  j.fire!(:run)
rescue AASMInvalidTransition => e
  puts e.message
  p [e.event, e.state]
end
j.ready = true
p j.permitted_events
p j.fire!(:run)
p j.current_state
p j.is?(:running)
p j.fire!(:clean)
p j.fire(:clean)
p j.fire!(:sleep)
p j.fire!(:run)
p j.fire!(:fail)
p j.current_state
p j.permitted_events
p j.log
begin
  j.fire(:explode)
rescue ArgumentError => e
  puts e.message
end

# two machines through the module's dispatch
light = TrafficLight.new
4.times do
  light.fire!(:next)
  print light.current_state, " "
end
puts
p light.permitted_events
p Job.new("other").permitted_events
p light.is?(:yellow)

# a bad machine
begin
  m = AASMMachine.new(:a)
  m.event(:go, from: :a, to: :b)
rescue ArgumentError => e
  puts e.message
end
