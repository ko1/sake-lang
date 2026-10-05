class Link
  attr_reader :item, :rest

  def initialize(item, rest)
    @item = item
    @rest = rest
  end
end

class Job
  attr_reader :id, :owner, :pages, :color

  def initialize(id, owner, pages, color)
    @id = id
    @owner = owner
    @pages = pages
    @color = color
  end

  def to_s = "##{@id} #{@owner} (#{@pages}p#{@color ? ", color" : ""})"
  def cost = @pages * (@color ? 15 : 4)
end

class TwoStackQueue
  attr_reader :size
  attr_accessor :transfers

  def initialize
    @inbox = nil
    @outbox = nil
    @size = 0
    @transfers = 0
  end

  def enqueue(x)
    @inbox = Link.new(x, @inbox)
    @size += 1
    self
  end

  def dequeue
    shift_over
    link = @outbox
    return nil if link.nil?
    @outbox = link.rest
    @size -= 1
    link.item
  end

  def peek
    shift_over
    @outbox&.item
  end

  def empty? = @size == 0

  private

  def shift_over
    return if @outbox
    while (link = @inbox)
      @outbox = Link.new(link.item, @outbox)
      @inbox = link.rest
      @transfers += 1
    end
  end
end

def spool(requests)
  q = TwoStackQueue.new
  next_id = 100
  printed = []
  per_owner = Hash.new(0)
  budget = { "ann" => 200, "bob" => 120, "cy" => 500 }
  requests.each do |req|
    case req
    in { print: owner, pages:, color: }
      next_id += 1
      job = Job.new(next_id, owner, pages, color)
      q.enqueue(job)
      puts "queued   #{job}"
    in { run: n }
      n.times do
        job = q.dequeue
        if job.nil?
          puts "idle     (queue empty)"
        else
          cost = job.cost
          left = budget.fetch(job.owner, 0) - per_owner[job.owner]
          if cost > left
            puts "rejected #{job}: cost #{cost} > budget left #{left}"
          else
            per_owner[job.owner] += cost
            printed << job
            puts "printed  #{job} cost #{cost}"
          end
        end
      end
    in { peek: true }
      nxt = q.peek
      puts "next up: #{nxt ? nxt.to_s : "nothing"}"
    end
  end
  [q, printed, per_owner]
end

requests = [
  { print: "ann", pages: 3, color: false },
  { print: "bob", pages: 10, color: true },
  { print: "cy", pages: 25, color: false },
  { peek: true },
  { run: 2 },
  { print: "ann", pages: 40, color: true },
  { print: "dan", pages: 1, color: false },
  { print: "bob", pages: 2, color: false },
  { peek: true },
  { run: 3 },
  { print: "cy", pages: 12, color: true },
  { run: 3 }
]

q, printed, spent = spool(requests)
puts "---"
puts "printed #{printed.size} jobs, #{printed.sum(&:pages)} pages"
puts "transfers between stacks: #{q.transfers}, still queued: #{q.size}"
spent.sort_by { |owner, _| owner }.each { |owner, total| puts format("  %-4s %4d", owner, total) }
biggest = printed.max_by(&:cost)
puts "most expensive: #{biggest}" if biggest
