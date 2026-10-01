# Merge two sensor time series keyed by minute: key-Set union, forward fill, moving averages, resampling.

def parse_series(text)
  text.split(";").to_h do |pair|
    t, v = pair.strip.split("=")
    [t.to_i, v == "na" ? nil : v.to_f]
  end
end

def forward_fill(keys, series)
  last = nil
  keys.to_h do |k|
    v = series[k]
    last = v unless !v    
    [k, last]
  end
end

def moving_average(values, n)
  values.each_cons(n).map do |win|
    nums = win.compact
    nums.empty? ? nil : nums.sum / nums.size
  end
end

def fmt(v) = !v     ? "  --" : format("%5.1f", v)

temp = parse_series("0=20.5; 1=20.7; 2=na; 3=21.4; 5=22.0; 6=22.4; 7=29.9; 8=22.9; 10=23.1; 11=23.0; 12=22.8")
hum = parse_series("0=45; 2=46; 3=47; 4=na; 5=49; 7=50; 9=52; 10=51; 13=50")

tk = temp.keys.to_set
hk = hum.keys.to_set
all_keys = (tk | hk).sort
puts "temp points: #{tk.size}, humidity points: #{hk.size}, merged minutes: #{all_keys.size}"
puts "only temp: #{(tk - hk).sort.join(",")}; only humidity: #{(hk - tk).sort.join(",")}"
nulls = all_keys.select { |k| temp.key?(k) && !temp[k]     }
puts "explicit gaps in temp: #{nulls.join(",")}"

span = (all_keys.first..all_keys.last).to_a
missing_minutes = span.reject { |m| (tk | hk).include?(m) }
puts "minutes with no reading at all: #{missing_minutes.empty? ? "none" : missing_minutes.join(",")}"

tf = forward_fill(span, temp)
hf = forward_fill(span, hum)
puts "== Merged (forward filled) =="
puts "  min  temp   hum"
span.each { |m| puts format("  %3d %s %s%s", m, fmt(tf[m]), fmt(hf[m]), !temp[m]     ? " *" : "") }

temps = span.map { |m| tf[m] }
ma = moving_average(temps, 3)
puts "== 3-minute moving average of temp =="
puts "  " + ma.map { |v| fmt(v).strip }.join(" ")

spikes = span.drop(1).zip(temps.drop(1), ma).filter_map do |m, v, avg|
  v && avg && (v - avg).abs > 3.0 ? m : nil
end
puts "spikes at minute: #{spikes.join(",")}"

puts "== 5-minute buckets =="
span.group_by { |m| m / 5 * 5 }.each do |start, mins|
  ts = mins.map { |m| temp[m] }.compact
  hs = mins.map { |m| hum[m] }.compact
  t_avg = ts.empty? ? nil : ts.sum / ts.size
  puts format("  %2d-%2d temp avg %s, humidity max %s, readings %d/%d", start, start + 4, fmt(t_avg), fmt(hs.max), ts.size + hs.size, mins.size * 2)
end
pairs = temps.zip(span.map { |m| hf[m] }).select { |t, h| t && h }
hot_humid = pairs.count { |t, h| t > 22.0 && h >= 50 }
puts "minutes above 22C with humidity >= 50: #{hot_humid}"
