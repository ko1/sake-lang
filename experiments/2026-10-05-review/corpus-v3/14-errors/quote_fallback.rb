# Fetch currency quotes from providers in priority order under a time budget, falling back to a stale cache.
class DeadlineExceeded < StandardError
  attr_reader :elapsed

  def initialize(message, elapsed)
    super(message)
    @elapsed = elapsed
  end
end

class ProviderDown < StandardError
  attr_reader :provider

  def initialize(message, provider)
    super(message)
    @provider = provider
  end
end

class BadQuote < StandardError
  attr_reader :provider, :value

  def initialize(message, provider, value)
    super(message)
    @provider = provider
    @value = value
  end
end

class Provider
  attr_reader :name, :latency, :rates
  attr_accessor :down

  def initialize(name, latency, rates, down)
    @name = name
    @latency = latency
    @rates = rates
    @down = down
  end
end

class Clock
  attr_accessor :now

  def initialize(now)
    @now = now
  end
end

def fetch_quote(provider, pair, clock, deadline)
  clock.now += provider.latency
  raise DeadlineExceeded.new("#{provider.name} too slow", clock.now) if clock.now > deadline
  raise ProviderDown.new("#{provider.name} unavailable", provider.name) if provider.down
  rate = provider.rates[pair]
  raise KeyError, "#{pair} not quoted" if rate.nil?
  raise BadQuote.new("non-positive rate", provider.name, rate) if rate <= 0
  rate
end

def quote_with_fallback(providers, pair, budget, cache, trail)
  clock = Clock.new(0)
  providers.each do |prov|
    rate = fetch_quote(prov, pair, clock, budget)
    trail << "#{prov.name}:ok"
    cache[pair] = rate
    return [rate, prov.name]
  rescue DeadlineExceeded => e
    trail << "#{prov.name}:timeout@#{e.elapsed}"
    return fallback(cache, pair, trail)
  rescue ProviderDown, KeyError
    trail << "#{prov.name}:skip"
  rescue BadQuote => e
    trail << "#{prov.name}:bad(#{e.value})"
  end
  fallback(cache, pair, trail)
end

def fallback(cache, pair, trail)
  rate = cache.fetch(pair)
  trail << "cache"
  [rate, "cache"]
end

providers = [
  Provider.new("fastfx", 40, { "USD/JPY" => 149.2, "EUR/USD" => 1.071, "GBP/USD" => 0.0 }, false),
  Provider.new("bankfeed", 120, { "USD/JPY" => 149.25, "EUR/JPY" => 159.8, "GBP/USD" => 1.262 }, false),
  Provider.new("slowcorp", 300, { "CHF/JPY" => 168.4, "AUD/USD" => 0.655 }, false)
]
cache = { "USD/JPY" => 148.9, "CHF/JPY" => 167.0 }

requests = [["USD/JPY", 500], ["EUR/JPY", 500], ["GBP/USD", 500], ["CHF/JPY", 200],
            ["AUD/USD", 200], ["AUD/USD", 1000], ["NZD/USD", 1000]]

def run(providers, requests, cache)
  requests.each do |pair, budget|
    trail = []
    begin
      rate, source = quote_with_fallback(providers, pair, budget, cache, trail)
      puts format("%-8s %5dms %9.3f from %-9s [%s]", pair, budget, rate, source, trail.join(" "))
    rescue KeyError
      puts format("%-8s %5dms       n/a no quote    [%s]", pair, budget, trail.join(" "))
    end
  end
end

run(providers, requests, cache)
puts "-- fastfx goes down"
providers[0].down = true
run(providers, [["USD/JPY", 100], ["EUR/USD", 500], ["USD/JPY", 500]], cache)
spread = (cache["USD/JPY"] rescue 0.0) - cache.fetch("EUR/JPY", 0.0)
puts "cached pairs: #{cache.keys.sort.join(" ")}; spread #{spread.round(2)}"
