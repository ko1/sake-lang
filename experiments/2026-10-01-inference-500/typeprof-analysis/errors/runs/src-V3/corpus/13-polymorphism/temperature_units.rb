class UnitError < StandardError
  attr_reader :unit
  def initialize(message, unit)
    super(message)
    @unit = unit
  end
end

# A difference between two temperatures, always in kelvin (= Celsius degrees).
class Delta
  include Comparable
  attr_reader :k
  def initialize(k)
    @k = k
  end
  def +(b) = Delta.new(@k + b.k)
  def *(s) = Delta.new(@k * s)
  def /(s) = Delta.new(@k / s)
  def <=>(b) = @k <=> b.k
  def in_unit(unit) = unit == :f ? @k * 9.0 / 5.0 : @k
  def to_s = format("%+.1f K", @k)
end

class Temp
  include Comparable
  attr_reader :value, :unit

  def initialize(value, unit)
    @value = value
    @unit = unit
  end

  def self.of(value, unit)
    raise UnitError.new("unknown unit #{unit}", unit) unless [:c, :f, :k].include?(unit)
    Temp.new(value * 1.0, unit)
  end

  def self.parse(s)
    m = s.match(/\A(-?\d+(?:\.\d+)?)\s*°?([CFK])\z/)
    raise UnitError.new("cannot read #{s}", :unknown) unless m
    of(m[1].to_f, m[2].downcase.to_sym)
  end

  def kelvin
    case @unit
    in :k then @value
    in :c then @value + 273.15
    in :f then (@value - 32) * 5.0 / 9.0 + 273.15
    end
  end

  def to(unit)
    k = kelvin
    v = case unit
        in :k then k
        in :c then k - 273.15
        in :f then (k - 273.15) * 9.0 / 5.0 + 32
        end
    Temp.new(v, unit)
  end

  def -(b)
    case b
    in Temp then Delta.new(kelvin - b.kelvin)
    in Delta then Temp.new(@value - b.in_unit(@unit), @unit)
    end
  end

  def +(d) = Temp.new(@value + d.in_unit(@unit), @unit)

  def <=>(b) = kelvin.round(6) <=> b.kelvin.round(6)

  def to_s
    sym = @unit == :k ? "K" : (@unit == :c ? "°C" : "°F")
    format("%.1f%s", @value, sym)
  end
end

class Reading
  attr_accessor :station, :hour, :temp
  def initialize(station, hour, temp)
    @station = station
    @hour = hour
    @temp = temp
  end
end

raw = [
  ["oslo", 6, "-3.5C"], ["oslo", 12, "2.0C"], ["oslo", 18, "-1C"],
  ["denver", 6, "28F"], ["denver", 12, "61.5F"], ["denver", 18, "45F"],
  ["lab", 6, "293.15K"], ["lab", 12, "294.6K"], ["lab", 18, "293.9K"],
  ["mars", 12, "-80R"], ["cairo", 12, "35.2C"], ["cairo", 18, "29.5C"]
]

readings = []
raw.each do |station, hour, text|
  begin
    readings << Reading.new(station, hour, Temp.parse(text))
  rescue UnitError => e
    puts "skip #{station}: #{e.message}"
  end
end

puts "== readings in Celsius =="
readings.each do |r|
  t = r.temp
  puts format("%-7s %02d:00 %10s = %8s", r.station, r.hour, t, t.to(:c))
end

puts "== per station =="
by_station = readings.group_by(&:station)
by_station.each do |station, rs|
  temps = rs.map(&:temp)
  lo = temps.min
  hi = temps.max
  swing = hi - lo
  unit = temps[0].unit
  mean_k = temps.sum(&:kelvin) / temps.size
  mean = Temp.new(mean_k, :k).to(unit)
  puts format("%-7s min %-8s max %-8s swing %-9s mean %s", station, lo, hi, swing, mean)
end

puts "== ranking at noon =="
noon = readings.select { |r| r.hour == 12 }
ranked = noon.sort_by { |r| -r.temp.kelvin }
ranked.each_with_index do |r, i|
  puts "#{i + 1}. #{r.station} #{r.temp.to(:c)}"
end
hottest = readings.max_by { |r| r.temp.kelvin }
puts "hottest overall: #{hottest.station} at #{hottest.hour}:00" if hottest

puts "== alerts =="
freezing = Temp.of(0, :c)
heat = Temp.of(95, :f)
readings.each do |r|
  t = r.temp
  if t <= freezing
    puts "frost: #{r.station} #{t} is #{freezing - t} below freezing"
  elsif t >= heat.to(:c) - Delta.new(5)
    puts "heat: #{r.station} #{t} within 5 K of #{heat}"
  end
end

puts "== arithmetic =="
a = Temp.of(20, :c)
b = Temp.of(68, :f)
puts "#{a} == #{b}? #{a == b}  (<=> says #{(a <=> b) == 0})"
puts "#{a} + 10 K = #{a + Delta.new(10)}"
puts "#{b} + 10 K = #{b + Delta.new(10)}"
puts "#{b} - 10 K = #{b - Delta.new(10)}"
puts "boiling - body = #{Temp.of(100, :c) - Temp.of(98.6, :f)}"
d = Delta.new(3) + Delta.new(4.5) * 2
puts "3 K + 2 * 4.5 K = #{d}, halved #{d / 2}, bigger than 10 K? #{d > Delta.new(10)}"
begin
  Temp.of(10, :r)
rescue UnitError => e
  puts "error: #{e.message} (#{e.unit})"
end
