# Response-time histogram: bucket latencies into Ranges (one endless), percentiles, and per-endpoint stats.

def buckets
  [
    ["fast", 0...50],
    ["ok", 50...200],
    ["slow", 200...1000],
    ["very slow", 1000..]
  ]
end

def samples
  text = "GET /home 12, GET /home 48, GET /home 51, POST /login 230, GET /search 180, " \
         "GET /search 950, GET /search 1200, POST /login 75, GET /home 9, GET /api/items 33, " \
         "GET /api/items 41, GET /api/items 260, POST /api/items 410, GET /search 199, " \
         "GET /home 3000, POST /login 88, GET /api/items 50, GET /search 640"
  text.split(", ").map do |entry|
    verb, path, ms = entry.split(" ")
    {verb: verb, path: path, ms: ms.to_i}
  end
end

def bucket_for(ms)
  found = buckets.find { |label, r| r.cover?(ms) }
  found ? found[0] : "?"
end

def percentile(sorted, pct)
  return nil if sorted.empty?
  rank = (pct / 100.0 * sorted.size).ceil - 1
  rank = 0 if rank < 0
  sorted[rank]
end

def range_label(r)
  hi = r.end
  if hi.nil?
    ">= #{r.begin}"
  elsif r.exclude_end?
    "#{r.begin}-#{hi - 1}"
  else
    "#{r.begin}-#{hi}"
  end
end

data = samples
times = data.map { |s| s[:ms] }.sort
puts "samples: #{times.size}, min #{times.first}, max #{times.last}"
puts format("mean: %.1f ms", times.sum / times.size.to_f)
[50, 90, 99].each { |pc| puts "p#{pc}: #{percentile(times, pc)} ms" }

counts = times.map { |t| bucket_for(t) }.tally
widest = buckets.map { |label, r| label.size }.max
puts "histogram:"
buckets.each do |label, r|
  n = counts.fetch(label, 0)
  puts format("  %-*s %-10s %2d %s", widest, label, range_label(r), n, "#" * n)
end

puts "per endpoint:"
groups = data.group_by { |s| "#{s[:verb]} #{s[:path]}" }
rows = groups.map do |key, list|
  ms = list.map { |s| s[:ms] }.sort
  [key, ms.size, percentile(ms, 50), ms.last]
end
rows.sort_by { |key, n, med, worst| -worst }.each do |key, n, med, worst|
  puts format("  %-16s n=%d median=%4d worst=%4d [%s]", key, n, med, worst, bucket_for(worst))
end

slo = 0...200
within = times.count { |t| slo.include?(t) }
puts format("within SLO %s: %d/%d (%.0f%%)", range_label(slo), within, times.size, within * 100.0 / times.size)
offenders = data.filter_map { |s| slo.cover?(s[:ms]) ? nil : s[:path] }.uniq
puts "paths breaking SLO: #{offenders.sort.join(", ")}"
p percentile([], 50)
step_hist = Hash.new(0)
times.each { |t| step_hist[t / 250 * 250] += 1 if t < 1000 }
(0...1000).step(250) { |lo| puts "  #{lo.to_s.rjust(3)}..#{lo + 249}: #{step_hist[lo]}" }
