class Turnstile
  attr_reader :state, :coins, :passes, :alarms

  def initialize
    @state = :locked
    @coins = 0
    @passes = 0
    @alarms = 0
  end

  def handle(event)
    case [@state, event]
    in [:locked, :coin]
      @coins += 1
      @state = :unlocked
      "unlock"
    in [:locked, :push]
      @alarms += 1
      "alarm"
    in [:unlocked, :coin]
      @coins += 1
      "thank you"
    in [:unlocked, :push]
      @passes += 1
      @state = :locked
      "lock"
    end
  end
end

events = [:push, :coin, :push, :coin, :coin, :push, :push, :push, :coin, :push]
t = Turnstile.new
actions = Hash.new(0)
events.each_with_index do |ev, i|
  before = t.state
  action = t.handle(ev)
  actions[action] += 1
  puts format("%2d %-8s %-6s -> %-8s %s", i + 1, before, ev, t.state, action)
end
puts "coins=#{t.coins} passes=#{t.passes} alarms=#{t.alarms}"
actions.sort_by { |a, n| [-n, a] }.each { |a, n| puts "  #{a}: #{n}" }
