#!/usr/bin/env ruby

require 'time'

endpoints = Hash.new { |h, k| h[k] = { count: 0, n4xx: 0, n5xx: 0, bytes: 0, durations: [] } }
hourly = Hash.new { |h, k| h[k] = 0 }
invalid_lines = []

ARGF.each_with_index do |line, idx|
  line_no = idx + 1
  line = line.chomp

  # Skip empty lines
  next if line.strip.empty?

  fields = line.split(/\s+/)

  # Check field count
  if fields.length != 6
    invalid_lines << { line: line_no, reason: "wrong field count" }
    next
  end

  timestamp_str, method, path, status_str, bytes_str, duration_str = fields

  # Parse timestamp
  if timestamp_str !~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/
    invalid_lines << { line: line_no, reason: "bad timestamp" }
    next
  end

  begin
    timestamp = Time.iso8601(timestamp_str)
  rescue
    invalid_lines << { line: line_no, reason: "bad timestamp" }
    next
  end

  # Check month, day, hour, minute, second
  if timestamp_str =~ /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})$/
    year, month, day, hour, minute, second = $1.to_i, $2.to_i, $3.to_i, $4.to_i, $5.to_i, $6.to_i
    if month < 1 || month > 12 || day < 1 || day > 31 || hour < 0 || hour > 23 || minute < 0 || minute > 59 || second < 0 || second > 59
      invalid_lines << { line: line_no, reason: "bad timestamp" }
      next
    end
  end

  # Validate method
  unless %w[GET POST PUT DELETE].include?(method)
    invalid_lines << { line: line_no, reason: "bad method" }
    next
  end

  # Validate path
  unless path.start_with?('/')
    invalid_lines << { line: line_no, reason: "bad path" }
    next
  end

  # Validate status
  unless status_str =~ /^\d{3}$/ && (100..599).include?(status_str.to_i)
    invalid_lines << { line: line_no, reason: "bad status" }
    next
  end
  status = status_str.to_i

  # Validate bytes
  if bytes_str == '-'
    bytes = 0
  elsif bytes_str =~ /^\d+$/
    bytes = bytes_str.to_i
  else
    invalid_lines << { line: line_no, reason: "bad bytes" }
    next
  end

  # Validate duration
  unless duration_str =~ /^\d+$/
    invalid_lines << { line: line_no, reason: "bad duration" }
    next
  end
  duration = duration_str.to_i

  # Extract endpoint (remove query string)
  clean_path = path.split('?')[0]
  endpoint = "#{method} #{clean_path}"

  # Update statistics
  endpoints[endpoint][:count] += 1
  endpoints[endpoint][:n4xx] += 1 if (400..499).include?(status)
  endpoints[endpoint][:n5xx] += 1 if (500..599).include?(status)
  endpoints[endpoint][:bytes] += bytes
  endpoints[endpoint][:durations] << duration

  # Track hourly data
  hour_key = timestamp.strftime('%Y-%m-%d %H:00')
  hourly[hour_key] += 1
end

if endpoints.empty?
  puts "no valid requests"
else
  # Sort endpoints: by count descending, then by endpoint name ascending
  sorted = endpoints.sort_by { |endpoint, stats| [-stats[:count], endpoint] }

  # Find max endpoint length
  max_len = sorted.map { |endpoint, _| endpoint.length }.max
  max_len = [max_len, 8].max

  # Print header
  puts format("%-#{max_len}s %5s %4s %4s %8s %7s %6s",
              "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")

  # Print rows
  sorted.each do |endpoint, stats|
    avg = stats[:durations].sum.to_f / stats[:durations].length
    max = stats[:durations].max

    # Format average with exactly one decimal place, rounded half up
    avg_str = format("%.1f", avg)

    puts format("%-#{max_len}s %5d %4d %4d %8d %7s %6d",
                endpoint, stats[:count], stats[:n4xx], stats[:n5xx],
                stats[:bytes], avg_str, max)
  end

  # Find busiest hour
  busiest_hour, count = hourly.max_by { |_, v| v }
  if hourly.length > 1
    # On tie, pick earliest
    busiest_hour = hourly.select { |_, v| v == count }.min[0]
  end

  puts "busiest hour: #{busiest_hour} (#{count} requests)"
end

# Print invalid lines
puts "invalid lines: #{invalid_lines.length}"
invalid_lines.each do |entry|
  puts "  line #{entry[:line]}: #{entry[:reason]}"
end
