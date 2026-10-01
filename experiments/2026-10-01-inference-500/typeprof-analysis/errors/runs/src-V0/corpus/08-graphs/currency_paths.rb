require "set"

class RateError < StandardError
  attr_reader :pair

  def initialize(message, pair)
    super(message)
    @pair = pair
  end
end

# Exchange rates as exact Rationals; an edge a->b with rate r implies b->a with 1/r.
def load_rates(quotes)
  graph = Hash.new { |h, k| h[k] = {} }
  quotes.each do |q|
    m = q.match(/\A(\w{3})\/(\w{3})\s*=\s*(\d+)(?:\/(\d+))?\z/)
    raise RateError.new("unreadable quote '#{q}'", q) unless m
    den = m[4] ? m[4].to_i : 1
    raise RateError.new("zero rate", q) if m[3].to_i == 0 || den == 0
    r = Rational(m[3].to_i, den)
    graph[m[1]][m[2]] = r
    graph[m[2]][m[1]] = 1 / r
  end
  graph
end

# DFS that accumulates the product of rates along the path.
def convert(graph, from, to)
  return nil unless graph.key?(from) && graph.key?(to)
  stack = [[from, 1r, [from]]]
  seen = Set[from]
  until stack.empty?
    cur, rate, path = stack.pop
    return [rate, path] if cur == to
    graph[cur].each do |nb, r|
      next unless seen.add?(nb)
      stack << [nb, rate * r, path + [nb]]
    end
  end
  nil
end

# A cycle whose product differs from 1 means the quotes are inconsistent.
def inconsistencies(graph)
  issues = []
  graph.keys.sort.each do |a|
    graph[a].each do |b, r_ab|
      next unless a < b
      graph[b].each do |c, r_bc|
        next unless b < c
        r_ca = graph[c][a]
        next if r_ca.nil?
        loop_rate = r_ab * r_bc * r_ca
        issues << "#{a}>#{b}>#{c}>#{a} = #{loop_rate}" if loop_rate != 1
      end
    end
  end
  issues
end

def show(amount, rate)
  (amount * rate).to_f.round(2)
end

def desk(title, quotes, asks)
  puts "== #{title}"
  graph = load_rates(quotes)
  puts "currencies: #{graph.keys.sort.join(" ")}"
  asks.each do |amount, from, to|
    found = convert(graph, from, to)
    if found
      rate, path = found
      puts "  #{amount} #{from} = #{show(amount, rate)} #{to}  (rate #{rate}, via #{path.join(">")})"
    else
      puts "  #{amount} #{from} -> #{to}: no conversion"
    end
  end
  issues = inconsistencies(graph)
  puts issues.empty? ? "  quotes are consistent" : "  inconsistent: #{issues.join("; ")}"
rescue RateError => e
  puts "  bad quotes: #{e.message}"
end

desk("morning", ["EUR/USD = 11/10", "USD/JPY = 150", "GBP/EUR = 6/5", "CHF/EUR = 21/20", "AUD/USD = 2/3"],
     [[100, "GBP", "JPY"], [250, "AUD", "CHF"], [1000, "JPY", "EUR"], [5, "EUR", "EUR"], [7, "EUR", "XYZ"]])
desk("stale feed", ["EUR/USD = 11/10", "USD/GBP = 4/5", "GBP/EUR = 6/5", "SEK/NOK = 1"],
     [[10, "SEK", "EUR"], [10, "NOK", "SEK"]])
desk("garbage", ["EUR/USD = 11/10", "EURUSD 1.1"], [])
