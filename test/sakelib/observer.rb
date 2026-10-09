require "observer"

# The subject: a ticker that notifies when the price changes.
class Ticker
  include Observable
  attr_reader :name
  attr_accessor :price
  def initialize(name)
    @name = name
    @price = 0
  end

  def set_price_and_notify(price)
    if price != @price
      @price = price
      changed
    end
    notify_observers(@name, price)
  end
end

# Observers are plain classes (found by identity, as Sake finds them by ==; a mutable Struct would
# change its hash while a key of Observable's Hash and become unfindable).
# Observer 1: prints a warning over a limit, counting the warnings.
class Warner
  attr_reader :limit
  attr_accessor :count
  def initialize(limit)
    @limit = limit
    @count = 0
  end
  def update(*args)
    price = args[1]
    if price in Integer
      if price > limit
        self.count += 1
        puts "Warner: #{args[0]} is #{price}, over #{limit}"
      end
    end
  end
end

# Observer 2: records every notification.
class Recorder
  attr_reader :log
  def initialize(log) = @log = log
  def update(*args) = log.push(args.map { |a| a.to_s }.join("@"))
end

t = Ticker.new("ACME")
warner = Warner.new(100)
rec = Recorder.new([])
p t.count_observers
p t.changed?
t.add_observer(warner)
t.add_observer(rec)
t.add_observer(warner)        # equal observer: not added twice
p t.count_observers

t.set_price_and_notify(90)
p t.changed?
t.set_price_and_notify(120)
t.set_price_and_notify(120)   # unchanged: observers not told
t.set_price_and_notify(150)
p warner.count
p rec.log

# changed(false) suppresses the next notification; changed? reflects it
t.changed
p t.changed?
t.changed(false)
p t.changed?
t.notify_observers("ACME", 0)
p rec.log.size

# notify with no arguments, and with a different number
class Bell
  attr_accessor :rings
  def initialize = @rings = 0
  def update(*args)
    self.rings += 1
    puts "Bell: #{args.size} args"
  end
end
bell = Bell.new
t.add_observer(bell)
t.changed
t.notify_observers
t.changed
t.notify_observers("ACME", 1, 2, 3)
p bell.rings
p rec.log.size

# delete: Sake finds the observer by ==, Ruby by identity; these cases agree
t.delete_observer(warner)
p t.count_observers
t.delete_observer(Warner.new(5))             # not there
p t.count_observers
t.set_price_and_notify(500)
p warner.count
t.delete_observer(Bell.new)                  # rings differ: not equal, not removed
p t.count_observers
t.delete_observers
p t.count_observers
t.set_price_and_notify(1000)
p bell.rings

# Two independent subjects do not share observers.
t2 = Ticker.new("ZZZ")
t2.add_observer(Recorder.new([]))
t.add_observer(bell)
p [t.count_observers, t2.count_observers]
t2.set_price_and_notify(7)
p bell.rings
