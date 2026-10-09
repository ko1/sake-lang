require "stringio"
require "ruby-progressbar"
require "ruby-progressbar/outputs/null"

# The gem honours format: and redraws only on a tty, so the output is a StringIO that says it is one;
# the time source is a fake clock (ProgressBar::Time takes anything with `now`). The gem's started?,
# stopped?, paused? give a Time or nil; `!!` makes them true/false, as Sake's are.
class FakeTty < StringIO
  def tty? = true
end

class Clock
  attr_accessor :now
  def initialize(t) = @now = t
end

out = FakeTty.new
clock = Clock.new(Time.at(1000))
bar = ProgressBar.create(total: 10, format: "%t: |%B| %p%% %c/%C", length: 50, output: out,
                         throttle_rate: 0, time: ProgressBar::Time.new(clock))
p bar.to_s
3.times { bar.increment }
p bar.to_s
p bar.progress
p bar.total
p bar.title
bar.progress = 7
puts bar.to_s
bar.title = "Files"
bar.progress_mark = "#"
bar.remainder_mark = "."
puts bar.to_s
p bar.finished?
bar.finish
p bar.finished?
p !!bar.stopped?
puts bar.to_s
p bar
# what the terminal would have received: a redraw per update, "\r" between, "\n" at the end
p out.string

# every molecule, with the time under control (3 seconds per step)
out2 = FakeTty.new
clock2 = Clock.new(Time.at(1000))
bar2 = ProgressBar.create(total: 8, length: 40, output: out2, throttle_rate: 0, time: ProgressBar::Time.new(clock2),
                          format: "%c/%C %a %e %r %R %l %E %f")
step = 3
2.times do
  clock2.now += step
  bar2.increment
  puts bar2.to_s
end
bar2.increment
puts bar2.to_s
bar2.pause
clock2.now += 10
puts bar2.to_s
p !!bar2.paused?
bar2.resume
puts bar2.to_s
bar2.log("hello from the log")
bar2.finish
puts bar2.to_s
puts bar2.to_s("%j|%J|%P|%w|%i|%T")
puts bar2.to_s("%W")
puts bar2.to_s("a%%b|%b|")
p out2.string
h = bar2.to_h
["length", "title", "progress", "total", "percentage", "elapsed_time_in_seconds",
 "estimated_time_remaining_in_seconds", "base_rate_of_change", "throttle_rate",
 "finished?"].each { |k| puts "#{k}: #{h[k].inspect}" }

# an unknown total: %u is ??, the bar animates
bar3 = ProgressBar.create(total: nil, output: ProgressBar::Outputs::Null, length: 30)
bar3.format = "%t: |%B| %u %c %p %P"
3.times do
  puts bar3.to_s
  bar3.increment
end
puts bar3.to_s("%i|%W|%w|%b|")
p bar3
bar3.total = 4
bar3.finish
puts bar3.to_s("%t: |%B| %u %c %p %P")

# a half-done bar with the percentage inside, starting_at, limits
bar4 = ProgressBar.create(total: 10, output: ProgressBar::Outputs::Null, length: 30, starting_at: 3)
bar4.format = "|%W| %j%%"
puts bar4.to_s
bar4.progress = 5
puts bar4.to_s
puts bar4.to_s("|%w|%i| %J %%")
begin
  bar4.progress = 11
rescue ProgressBar::InvalidProgressError => e
  puts e.message
end
bar4.total = 20
puts bar4.to_s("%c/%C %p%%")
begin
  bar4.total = 2
rescue ProgressBar::InvalidProgressError => e
  puts e.message
end
bar4.reset
p bar4.progress
p !!bar4.started?
puts bar4.to_s("%a %e")

# autofinish: false, and the warnings at the ends (on stderr)
bar5 = ProgressBar.create(total: 3, output: ProgressBar::Outputs::Null, length: 20, autofinish: false)
bar5.format = "%B"
3.times { bar5.increment }
p bar5.finished?
p !!bar5.stopped?
bar5.increment
bar5.decrement
p bar5.progress
bar5.finish
p bar5.finished?
bar5.progress = 0
bar5.decrement
p bar5.progress

# a total of 0 is complete at once; a coloured format does not count its escape codes
puts ProgressBar.create(total: 0, output: FakeTty.new, length: 20, format: "|%B| %p %P").to_s
puts ProgressBar.create(total: 4, output: FakeTty.new, length: 20, format: "\e[31m%t\e[0m |%B|", progress_mark: "*").to_s
puts ProgressBar.create(total: 4, output: FakeTty.new, length: 3, format: "%t: |%B|").to_s
begin
  ProgressBar.create(total: 4, output: FakeTty.new, format: "%z").to_s
rescue KeyError => e
  puts e.message
end
