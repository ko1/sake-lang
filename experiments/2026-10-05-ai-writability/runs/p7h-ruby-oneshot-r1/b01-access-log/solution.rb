#!/usr/bin/env ruby

def parse_timestamp(ts)
  return nil unless ts =~ /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/

  year, month, day, hour, minute, second = ts.scan(/\d+/)
  month = month.to_i
  day = day.to_i
  hour = hour.to_i

  return nil if month < 1 || month > 12
  return nil if day < 1 || day > 31
  return nil if hour > 23

  ts
end

def validate_line(fields, line_num)
  return ["wrong field count", nil] if fields.length != 6

  timestamp, method, path, status, bytes, duration = fields

  return ["bad timestamp", nil] unless parse_timestamp(timestamp)
  return ["bad method", nil] unless ["GET", "POST", "PUT", "DELETE"].include?(method)
  return ["bad path", nil] unless path.start_with?("/")
  return ["bad status", nil] unless status =~ /^\d{3}$/ && (100..599).include?(status.to_i)
  return ["bad bytes", nil] unless bytes == "-" || bytes =~ /^\d+$/
  return ["bad duration", nil] unless duration =~ /^\d+$/

  [nil, {
    timestamp: timestamp,
    method: method,
    path: path.split("?")[0],
    status: status.to_i,
    bytes: bytes == "-" ? 0 : bytes.to_i,
    duration: duration.to_i
  }]
end

endpoints = {}
invalid_lines = []
hours = {}

STDIN.each_with_index do |line, idx|
  line_num = idx + 1
  line = line.rstrip("\n")

  next if line.empty? || line.strip.empty?

  fields = line.split(/\s+/)

  error, data = validate_line(fields, line_num)

  if error
    invalid_lines << [line_num, error]
  else
    endpoint = "#{data[:method]} #{data[:path]}"
    endpoints[endpoint] ||= {
      count: 0, n4xx: 0, n5xx: 0, bytes: 0, durations: []
    }

    endpoints[endpoint][:count] += 1
    endpoints[endpoint][:n4xx] += 1 if (400..499).include?(data[:status])
    endpoints[endpoint][:n5xx] += 1 if (500..599).include?(data[:status])
    endpoints[endpoint][:bytes] += data[:bytes]
    endpoints[endpoint][:durations] << data[:duration]

    hour_key = data[:timestamp][0..12]
    hours[hour_key] ||= 0
    hours[hour_key] += 1
  end
end

if endpoints.empty?
  puts "no valid requests"
else
  sorted_endpoints = endpoints.sort do |a, b|
    cmp = b[1][:count] <=> a[1][:count]
    cmp.zero? ? a[0] <=> b[0] : cmp
  end

  max_width = [8, sorted_endpoints.map { |k, _| k.length }.max].max

  header = format("%-#{max_width}s %5s %4s %4s %8s %7s %6s",
                  "endpoint", "count", "4xx", "5xx", "bytes", "avg_ms", "max_ms")
  puts header

  sorted_endpoints.each do |endpoint, stats|
    durations = stats[:durations]
    avg = durations.empty? ? 0.0 : (durations.sum.to_f / durations.length)
    max = durations.max || 0

    avg_str = format("%.1f", avg)

    puts format("%-#{max_width}s %5d %4d %4d %8d %7s %6d",
                endpoint, stats[:count], stats[:n4xx], stats[:n5xx],
                stats[:bytes], avg_str, max)
  end

  busiest_hour = hours.max_by { |_, count| count }
  hour_str = "#{busiest_hour[0][0..9]} #{busiest_hour[0][11..12]}:00"
  puts "busiest hour: #{hour_str} (#{busiest_hour[1]} requests)"
end

puts "invalid lines: #{invalid_lines.length}"
invalid_lines.each do |line_num, reason|
  puts "  line #{line_num}: #{reason}"
end
