class Person
  attr_reader :name
  attr_accessor :state, :days_sick, :infected_by, :infected_on

  def initialize(name, state)
    @name = name
    @state = state
    @days_sick = 0
    @infected_by = nil
    @infected_on = nil
  end
end

class Lcg
  def initialize(seed)
    @seed = seed
  end

  def roll
    @seed = (@seed * 214013 + 2531011) % 4294967296
    (@seed / 65536) % 1000
  end
end

def build_graph(edges)
  graph = Hash.new { |h, k| h[k] = [] }
  edges.each do |a, b|
    graph[a] << b
    graph[b] << a
  end
  graph
end

def simulate(graph, patient_zero, vaccinated, beta, recover_days, seed)
  rng = Lcg.new(seed)
  people = {}
  graph.keys.sort.each do |name|
    state = vaccinated.include?(name) ? :recovered : :susceptible
    people[name] = Person.new(name, state)
  end
  zero = people[patient_zero]
  zero.state = :infected
  zero.infected_on = 0
  curve = []
  day = 0
  while people.any? { |_n, p| p.state == :infected }
    day += 1
    sick = people.values.select { |p| p.state == :infected }
    newly = []
    sick.each do |p|
      graph[p.name].each do |other_name|
        other = people[other_name]
        next unless other.state == :susceptible
        next if newly.include?(other)
        if rng.roll < beta
          newly << other
          other.infected_by = p.name
        end
      end
    end
    sick.each do |p|
      p.days_sick += 1
      p.state = :recovered if p.days_sick >= recover_days
    end
    newly.each do |p|
      p.state = :infected
      p.infected_on = day
    end
    counts = people.values.map(&:state).tally
    curve << [day, counts.fetch(:susceptible, 0), counts.fetch(:infected, 0), counts.fetch(:recovered, 0)]
  end
  [people, curve]
end

def chain(people, name)
  links = [name]
  cur = people[name]
  while cur
    src = cur.infected_by
    break if src.nil?
    links << src
    cur = people[src]
  end
  links.reverse.join(" > ")
end

def report(title, graph, vaccinated)
  people, curve = simulate(graph, "ann", vaccinated, 350, 3, 42)
  puts "== #{title}"
  curve.each do |day, s, i, r|
    puts format("day %2d  S %2d  I %2d  R %2d  %s", day, s, i, r, "*" * i)
  end
  infected = people.values.select(&:infected_on)
  peak = curve.max_by { |_d, _s, i, _r| i }
  if peak
    pd, _ps, pi, _pr = peak
    puts "peak: #{pi} infected on day #{pd}"
  end
  puts "total infected: #{infected.size} of #{people.size}"
  spreaders = infected.filter_map(&:infected_by).tally
  top = spreaders.max_by { |_n, c| c }
  if top
    who, count = top
    puts "top spreader: #{who} (#{count})"
  end
  last = infected.max_by(&:infected_on)
  puts "longest chain: #{chain(people, last.name)}" if last
  infected.size
end

edges = [
  ["ann", "bob"], ["ann", "cy"], ["ann", "dee"], ["bob", "cy"], ["bob", "eli"],
  ["cy", "fay"], ["dee", "gil"], ["eli", "fay"], ["eli", "hal"], ["fay", "ivy"],
  ["gil", "hal"], ["gil", "jo"], ["hal", "kai"], ["ivy", "kai"], ["jo", "kai"],
  ["kai", "lee"], ["lee", "max"], ["max", "ned"], ["ned", "oz"], ["lee", "oz"],
  ["fay", "pat"], ["pat", "quin"], ["quin", "ivy"], ["dee", "eli"]
]
graph = build_graph(edges)
degrees = graph.sort_by { |n, nbrs| [-nbrs.size, n] }
puts "most connected: #{degrees.take(3).map { |n, nbrs| "#{n}(#{nbrs.size})" }.join(" ")}"

base = report("no vaccination", graph, [])
hubs = degrees.take(3).map(&:first)
hubs.delete("ann")
targeted = report("vaccinate hubs #{hubs.join(",")}", graph, hubs)
puts format("infections avoided: %d (%.0f%%)", base - targeted, 100.0 * (base - targeted) / base)
