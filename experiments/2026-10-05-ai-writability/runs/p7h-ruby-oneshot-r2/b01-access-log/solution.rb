valid_requests = []
invalid_lines = []

$stdin.each_line.with_index(1) do |line, line_num|
  line = line.chomp
  next if line.strip.empty?

  fields = line.split(/\s+/)

  # Validate field count
  if fields.length != 6
    invalid_lines << [line_num, "wrong field count"]
    next
  end

  timestamp, method, path, status, bytes, duration = fields

  # Validate timestamp
  unless timestamp =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/
    invalid_lines << [line_num, "bad timestamp"]
    next
  end

  year, month, day, hour, min, sec = timestamp.scan(/\d+/).map(&:to_i)
  if month < 1 || month > 12 || day < 1 || day > 31 || hour > 23 || min > 59 || sec > 59
    invalid_lines << [line_num, "bad timestamp"]
    next
  end

  # Validate method
  unless ['GET', 'POST', 'PUT', 'DELETE'].include?(method)
    invalid_lines << [line_num, "bad method"]
    next
  end

  # Validate path
  unless path.start_with?('/')
    invalid_lines << [line_num, "bad path"]
    next
  end

  # Validate status
  unless status =~ /^\d{3}$/ && (100..599).include?(status.to_i)
    invalid_lines << [line_num, "bad status"]
    next
  end

  # Validate bytes
  unless bytes == '-' || bytes =~ /^\d+$/
    invalid_lines << [line_num, "bad bytes"]
    next
  end

  # Validate duration
  unless duration =~ /^\d+$/
    invalid_lines << [line_num, "bad duration"]
    next
  end

  # Record valid request
  valid_requests << {
    timestamp: timestamp,
    method: method,
    path: path.split('?')[0],
    status: status.to_i,
    bytes: bytes == '-' ? 0 : bytes.to_i,
    duration: duration.to_i,
    hour: timestamp[0..12].gsub('T', ' ') + ':00'
  }
end

if valid_requests.empty?
  puts "no valid requests"
else
  # Group by endpoint
  endpoints = Hash.new { |h, k| h[k] = {count: 0, n4xx: 0, n5xx: 0, bytes: 0, durations: []} }

  valid_requests.each do |req|
    endpoint = "#{req[:method]} #{req[:path]}"
    endpoints[endpoint][:count] += 1
    endpoints[endpoint][:n4xx] += 1 if (400...500).include?(req[:status])
    endpoints[endpoint][:n5xx] += 1 if (500..599).include?(req[:status])
    endpoints[endpoint][:bytes] += req[:bytes]
    endpoints[endpoint][:durations] << req[:duration]
  end

  # Sort by count (desc) then endpoint (asc)
  sorted_endpoints = endpoints.sort_by { |ep, data| [-data[:count], ep] }

  # Calculate widths
  max_width = [sorted_endpoints.map { |ep, _| ep.length }.max || 8, 8].max

  # Print table
  puts format("%-#{max_width}s %5s %4s %4s %8s %7s %6s", "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")

  sorted_endpoints.each do |endpoint, data|
    avg = (data[:durations].sum.to_f / data[:count]).round(1)
    max_ms = data[:durations].max
    puts format("%-#{max_width}s %5d %4d %4d %8d %7.1f %6d", endpoint, data[:count], data[:n4xx], data[:n5xx], data[:bytes], avg, max_ms)
  end

  # Find busiest hour
  hours = Hash.new(0)
  valid_requests.each { |req| hours[req[:hour]] += 1 }

  busiest = hours.sort_by { |hour, count| [-count, hour] }.first
  puts "busiest hour: #{busiest[0]} (#{busiest[1]} requests)"
end

# Print invalid lines
puts "invalid lines: #{invalid_lines.length}"
invalid_lines.each { |line_num, reason| puts "  line #{line_num}: #{reason}" }
