require_relative "ref/units"

speed = Unit.new(90, "km/h")
puts speed
p speed
p speed.scalar
p speed.units
p speed.kind
puts speed.convert_to("m/s")
puts speed.convert_to("mi/h")
puts speed.to_base

# length, mass, time
[["1 mi", "km"], ["12 in", "ft"], ["5280 ft", "mi"], ["100 cm", "m"], ["2.5 kg", "lb"],
 ["16 oz", "lb"], ["1 t", "g"], ["90 min", "h"], ["1 day", "s"], ["250 ms", "s"],
 ["3 L", "cm^3"], ["1 m^2", "cm^2"]].each do |from, to|
  u = Unit.parse(from)
  puts "#{u} = #{u.convert_to(to)} (#{u.kind})"
end

# compound units
g = Unit.parse("9.81 m/s^2")
p g.kind
puts g.convert_to("km/h^2")
mass = Unit.new(70, "kg")
force = mass * g
puts force
p force.kind
puts force.convert_to("N")
work = force.convert_to("N") * Unit.new(2, "m")
puts work
p work.kind
distance = Unit.new(42.195, "km")
time = Unit.new(2, "h") + Unit.new(35, "min")
puts time
pace = distance / time
puts pace
puts pace.convert_to("m/s")
p (Unit.new(1, "km") / Unit.new(200, "m")).kind
puts Unit.new(1, "km") / Unit.new(200, "m")
puts Unit.new(3, "m") * Unit.new(4, "m")
puts Unit.new(10, "m^3") / Unit.new(2, "m")
puts Unit.new(120, "1/min")
puts Unit.new(120, "1/min").convert_to("1/s")
p Unit.new(1, "kg*s").kind

# arithmetic and comparison
a = Unit.new(1, "km")
b = Unit.new(300, "m")
puts a + b
puts b + a
puts a - b
puts a * 3
puts a / 4
p a > b
p Unit.new(1, "mi") > Unit.new(1600, "m")
p Unit.new(100, "cm") == Unit.new(1, "m")
p [Unit.new(1, "mi"), Unit.new(1, "km"), Unit.new(3000, "ft"), Unit.new(500, "yd")].sort
p [Unit.new(1, "h"), Unit.new(3000, "s"), Unit.new(70, "min")].max
p a.compatible?(Unit.new(1, "ft"))
p a.compatible?(Unit.new(1, "s"))
puts Unit.new(1, "mi").convert_to("km").round(2)

# errors
["5 parsecs", "abc", "5 m/s/s", "5 m^x"].each do |s|
  begin
    Unit.parse(s)
  rescue ArgumentError => e
    puts e.message
  end
end
begin
  speed.convert_to("kg")
rescue ArgumentError => e
  puts e.message
end
begin
  a + Unit.new(1, "s")
rescue ArgumentError => e
  puts e.message
end
begin
  a < Unit.new(1, "kg")
rescue ArgumentError => e
  puts e.message
end
begin
  Unit.new([1, "5"].fetch(1), "m")
rescue NoMatchingPatternError
  puts "the scalar must be a number"
end
