require 'time'

lines = STDIN.readlines
endpoints = {}
hour_counts = {}
invalid_lines = []

lines.each_with_index do |line, idx|
  line_num = idx + 1

  # Skip empty or whitespace-only lines
  next if line.strip.empty?

  fields = line.split

  # Check field count
  if fields.length != 6
    invalid_lines << [line_num, "wrong field count"]
    next
  end

  timestamp_str, method, path, status, bytes_str, duration_str = fields

  # Validate timestamp
  if !timestamp_str.match?(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/)
    invalid_lines << [line_num, "bad timestamp"]
    next
  end

  begin
    timestamp = Time.iso8601(timestamp_str)
    # Check if date/time is valid
    month = timestamp.month
    day = timestamp.day
    hour = timestamp.hour
    if month < 1 || month > 12 || day < 1 || day > 31 || hour > 23
      raise "Invalid date/time"
    end
  rescue
    invalid_lines << [line_num, "bad timestamp"]
    next
  end

  # Validate method
  unless %w[GET POST PUT DELETE].include?(method)
    invalid_lines << [line_num, "bad method"]
    next
  end

  # Validate path
  unless path.start_with?('/')
    invalid_lines << [line_num, "bad path"]
    next
  end

  # Validate status
  unless status.match?(/^\d{3}$/) && status.to_i >= 100 && status.to_i <= 599
    invalid_lines << [line_num, "bad status"]
    next
  end

  # Validate bytes
  bytes = if bytes_str == '-'
    nil
  elsif bytes_str.match?(/^\d+$/)
    bytes_str.to_i
  else
    invalid_lines << [line_num, "bad bytes"]
    next
  end

  # Validate duration
  unless duration_str.match?(/^\d+$/)
    invalid_lines << [line_num, "bad duration"]
    next
  end

  duration = duration_str.to_i
  status_code = status.to_i

  # Remove query string from path
  clean_path = path.split('?').first
  endpoint = "#{method} #{clean_path}"

  # Record endpoint data
  endpoints[endpoint] ||= {
    count: 0,
    n4xx: 0,
    n5xx: 0,
    bytes: 0,
    durations: []
  }

  endpoints[endpoint][:count] += 1
  endpoints[endpoint][:n4xx] += 1 if status_code >= 400 && status_code < 500
  endpoints[endpoint][:n5xx] += 1 if status_code >= 500
  endpoints[endpoint][:bytes] += bytes if bytes
  endpoints[endpoint][:durations] << duration

  # Track busiest hour
  hour_key = timestamp.strftime("%Y-%m-%d %H:00")
  hour_counts[hour_key] ||= 0
  hour_counts[hour_key] += 1
end

# Output
if endpoints.empty?
  puts "no valid requests"
else
  # Calculate max endpoint length (at least 8)
  max_len = [endpoints.keys.map(&:length).max, 8].max

  # Header
  puts format("%-#{max_len}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")

  # Sort by count (descending), then by endpoint (byte order)
  sorted_endpoints = endpoints.sort do |a, b|
    count_cmp = b[1][:count] <=> a[1][:count]
    count_cmp != 0 ? count_cmp : a[0] <=> b[0]
  end

  # Data rows
  sorted_endpoints.each do |endpoint, data|
    avg = data[:durations].sum.to_f / data[:durations].length
    max = data[:durations].max
    avg_str = format("%.1f", avg)

    puts format("%-#{max_len}s %5d %4d %4d %8d %7s %6d",
                endpoint, data[:count], data[:n4xx], data[:n5xx],
                data[:bytes], avg_str, max)
  end

  # Busiest hour
  busiest = hour_counts.max_by { |k, v| [v, -Time.parse(k).to_i] }
  busiest_hour, busiest_count = busiest
  puts "busiest hour: #{busiest_hour} (#{busiest_count} requests)"
end

# Invalid lines
puts "invalid lines: #{invalid_lines.length}"
invalid_lines.each do |line_num, reason|
  puts "  line #{line_num}: #{reason}"
end
