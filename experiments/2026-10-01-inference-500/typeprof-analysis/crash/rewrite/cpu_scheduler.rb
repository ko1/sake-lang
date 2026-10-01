class Job
  attr_reader :pid, :arrival, :burst, :priority
  attr_accessor :remaining, :finished, :first_run

  def initialize(pid, arrival, burst, priority)
    @pid = pid
    @arrival = arrival
    @burst = burst
    @priority = priority
    @remaining = burst
    @finished = nil
    @first_run = nil
  end
end

module Scheduler
  def run(specs)
    jobs = specs.map { |pid, arr, burst, prio| Job.new(pid, arr, burst, prio) }
    ready = []
    timeline = []
    clock = 0
    current = nil
    slice_used = 0
    while jobs.any? { |j| j.finished.nil? }
      jobs.each { |j| ready << j if j.arrival == clock }
      if current && preempt?(current, ready, slice_used)
        ready << current
        current = nil
      end
      if current.nil?
        current = pick(ready)
        ready.delete(current) if current
        slice_used = 0
      end
      if current.nil?
        timeline << "."
      else
        current.first_run ||= clock
        current.remaining -= 1
        timeline << current.pid
        slice_used += 1
      end
      clock += 1
      if current && current.remaining == 0
        current.finished = clock
        current = nil
      end
    end
    [jobs, timeline]
  end

  def report(specs)
    jobs, timeline = run(specs)
    puts "== #{label}"
    puts "  |#{timeline.join}|"
    switches = timeline.each_cons(2).count { |a, b| a != b }
    total_turn = 0
    total_wait = 0
    total_resp = 0
    jobs.each do |j|
      turnaround = j.finished - j.arrival
      wait = turnaround - j.burst
      total_turn += turnaround
      total_wait += wait
      total_resp += j.first_run - j.arrival
      puts format("  %s arrive %2d burst %2d prio %d -> done %2d turnaround %2d wait %2d",
        j.pid, j.arrival, j.burst, j.priority, j.finished, turnaround, wait)
    end
    n = jobs.size.to_f
    puts format("  avg turnaround %.2f  avg wait %.2f  avg response %.2f  switches %d",
      total_turn / n, total_wait / n, total_resp / n, switches)
    total_wait / n
  end
end

class Fcfs
  include Scheduler
  def label = "FCFS"
  def pick(ready) = ready.first
  def preempt?(_current, _ready, _used) = false
end

class RoundRobin
  include Scheduler
  attr_reader :quantum

  def initialize(quantum)
    @quantum = quantum
  end

  def label = "Round robin (q=#{@quantum})"
  def pick(ready) = ready.first
  def preempt?(_current, ready, used) = used >= @quantum && !ready.empty?
end

class Srtf
  include Scheduler
  def label = "Shortest remaining time first"
  def pick(ready) = ready.min_by { |j| [j.remaining, j.arrival] }

  def preempt?(current, ready, _used)
    best = pick(ready)
    !best.nil? && best.remaining < current.remaining
  end
end

class PriorityPreemptive
  include Scheduler
  def label = "Priority, preemptive"
  def pick(ready) = ready.min_by { |j| [j.priority, j.arrival] }

  def preempt?(current, ready, _used)
    best = pick(ready)
    !best.nil? && best.priority < current.priority
  end
end

specs = [
  ["A", 0, 7, 3], ["B", 1, 4, 1], ["C", 2, 9, 4], ["D", 3, 2, 2],
  ["E", 6, 5, 1], ["F", 10, 3, 5], ["G", 12, 1, 2]
]

results = [
  ["FCFS", Fcfs.new.report(specs)],
  ["RR2", RoundRobin.new(2).report(specs)],
  ["RR4", RoundRobin.new(4).report(specs)],
  ["SRTF", Srtf.new.report(specs)],
  ["PRIO", PriorityPreemptive.new.report(specs)]
]

puts "--- ranking by average wait"
results.sort_by { |e__| _name, w = e__; w }.each_with_index do |(name, w), i|
  puts format("%d. %-5s %6.2f", i + 1, name, w)
end
