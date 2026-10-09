require "bigdecimal"
require "bigdecimal/util"

# The same program with Ruby's BigDecimal. Sake's round/floor/ceil/truncate always give a BigDecimal
# (Ruby gives an Integer without digits), so s() shows an Integer as a BigDecimal.

def d(x) = BigDecimal(x)
def s(x) = (x.is_a?(Integer) ? BigDecimal(x) : x).to_s
def f(x) = x.to_s("F")
def show(label, *xs) = puts("#{label}: #{xs.map { |x| s(x) }.join(" ")}")

# parsing and to_s (Ruby's "0.123e1" form)
show("parse", d("1.23"), d("-0"), d("0"), d("100"), d("0.001"), d("1e3"), d("  1.5  "), d("1_000.5"), d(".5"), d("5."), d("+.5"), d("1E+3"), d("1e-3"), d("0.0e5"), d("00012.3400"), d("12_"), d("1e1_0"), d("1d3"), d("-1.5e+2"))
show("special", d("Infinity"), d("-Infinity"), d("+Infinity"), d("NaN"), BigDecimal::NAN, BigDecimal::INFINITY, -BigDecimal::INFINITY)
["abc", "", "1.2.3", "1e", "1x", "1 2", "1__2", "_12", "+-1", "0x10", "1,5", "Inf", "nan", "  ", "-", "."].each do |x|
  begin
    d(x)
    puts("parsed #{x.inspect}")
  rescue ArgumentError => e
    puts("ArgumentError: #{e.message}")
  end
end
show("from_i", BigDecimal(12), BigDecimal(-0), BigDecimal(10 ** 30), BigDecimal(-7))
show("from_f", BigDecimal(1.5), BigDecimal(0.1), BigDecimal(1.0 / 3, 5), BigDecimal(1.0 / 3), BigDecimal(1e20), BigDecimal(Float::NAN), BigDecimal(-Float::INFINITY), BigDecimal(-0.0))
show("from_r", BigDecimal(1r / 3, 10), BigDecimal(3r / 2, 5), BigDecimal(-2r / 3, 4))
begin
  BigDecimal(1.0 / 3, 20)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end
show("from_r0", BigDecimal(1r / 3, 0), BigDecimal(123456789r / 7, 0), BigDecimal(1r / 2, 0))   # Sake: from_r(r) defaults prec to 0

# plain form and the format string
puts(f(d("1.23")), f(d("100")), f(d("0.001")), f(d("0")), f(d("-0")), f(d("-12.5")), f(d("1e20")), f(d("1e-20")), f(d("NaN")), f(d("-Infinity")))
puts(d("1.23").to_s("+"), d("-1.23").to_s("+"), d("1.23").to_s(" F"), d("1234.5678").to_s("3F"), d("1234.5678").to_s(3), d("12345678.123456789").to_s("3F"), d("-12345678.123456789").to_s("+3F"), d("12345678.123456789").to_s(3), d("1.23").to_s("E"), d("1.23").to_s("f"), d("0").to_s("+"), d("NaN").to_s("+"), d("Infinity").to_s("+F"), d("1.23").to_s("5F"))
p(d("1.5"))
puts("#{d("2.5")} and #{d("-0.25").inspect}")
p([d("1"), d("2.5")])

# exact arithmetic, with Integers and Floats
show("add", d("1.5") + d("2.25"), d("1.5") + 1, d("0.1") + d("0.2"), d("1e20") + 1, d("1.5") - d("1.5"), d("-1.5") + d("1.5"), d("1.5") + 0.1, d("1.5") - 1.5)
show("sub", d("1.5") - d("2.25"), d("10") - 3, d("0") - d("0.001"))
show("mul", d("1.5") * d("2.25"), d("1.5") * 2, d("0") * -1, d("1.5") * 0, d("-1.5") * 0, d("1.5") * 0.1, d("123456789") * d("987654321"), d("1e-10") * d("1e-10"))
show("neg", -d("1.5"), -d("0"), +d("1.5"), d("-1.5").abs, d("-Infinity").abs, d("NaN").abs)
show("prec", d("1.5").add(d("2.25"), 2), d("1.5").sub(d("2.25"), 2), d("1.5").mult(d("2.25"), 2), d("1.5").add(1, 0), d("123.456").add(0, 2), d("123.456").mult(1, 4), d("125").add(0, 2))

# NaN and Infinity propagate
show("nan", d("NaN") + 1, d("Infinity") + 1, d("Infinity") - d("Infinity"), d("Infinity") * 0, d("Infinity") * -2, d("1") / d("Infinity"), d("Infinity") / 2, d("Infinity") / d("Infinity"), d("NaN") + d("NaN"), d("-Infinity") + d("-Infinity"), d("1") - d("Infinity"), d("NaN") * d("Infinity"))

# division: Ruby's default precision, and div with digits
show("div", d("1") / d("3"), d("2") / d("3"), d("1") / d("7"), d("10") / d("3"), d("1000") / d("3"), d("1.5") / d("7"), d("1") / d("300"), d("1.23456789") / d("3"), d("123456789012345678") / d("7"), d("22") / d("7"), d("1") / d("-3"), d("-1") / d("3"), d("0.1") / d("3"), d("1") / d("0.3"), d("1") / d("3e10"), d("1e10") / d("3"), d("1") / d("7e-5"), d("7") / d("11"), d("1") / 3, d("1") / 3.0, d("1") / 0, d("-1") / 0, d("0") / 0, d("1") / d("-0"), d("0") / 3, d("3") / 8)
show("divn", d("1").div(3, 5), d("1").div(3, 0), d("2").div(3, 20), d("2").div(3, 1), d("200").div(3, 2), d("1").div(0, 5), d("0").div(0, 5), d("3").div(d("0.7"), 3), d("1.5").quo(3), d("1.5").quo(3, 2), d("1").div(d("7"), 40))
p([d("1").div(3), d("7").div(2), d("-7").div(2), d("7.5").div(d("0.7"))])
begin
  d("1").div(0)
rescue ZeroDivisionError => e
  puts("ZeroDivisionError: #{e.message}")
end

# modulo, divmod, remainder
show("mod", d("7") % 3, d("-7") % 3, d("7.5") % 2, d("7") % d("2.5"), d("7").modulo(-3), d("7").remainder(3), d("-7").remainder(3), d("7.5").remainder(2), d("Infinity") % 2, d("7") % d("Infinity"), d("NaN") % 2)
p(d("7").divmod(3).map { |x| x.to_s })
p(d("-7").divmod(3).map { |x| x.to_s })
p(d("7.5").divmod(2).map { |x| x.to_s })
p(d("7.5").divmod(d("0.7")).map { |x| x.to_s })
begin
  d("7") % 0
rescue ZeroDivisionError => e
  puts("ZeroDivisionError: #{e.message}")
end
begin
  d("Infinity").divmod(2)
rescue FloatDomainError => e
  puts("FloatDomainError: #{e.message}")
end

# powers
show("pow", d("1.5") ** 2, d("1.5") ** 0, d("2") ** -2, d("3") ** -1, d("1.5") ** 10, d("2").power(3), d("0") ** 0, d("0") ** -1, d("-2") ** 3, d("-2") ** -3, d("0") ** 2, d("-0") ** -1, d("3") ** -2, d("1.1") ** -3, d("1.1") ** 20, d("1.1").power(20, 5), d("2").power(-1, 5), d("2").power(10, 3), d("Infinity") ** 2, d("Infinity") ** -2, d("NaN") ** 2, d("-Infinity") ** 3, d("-Infinity") ** 2)
p(s(d("1.5") ** 100).length)

# sqrt
show("sqrt", d("2").sqrt(10), d("2").sqrt(1), d("2").sqrt(20), d("4").sqrt(10), d("0.25").sqrt(5), d("100").sqrt(5), d("2").sqrt(0), d("0").sqrt(5), d("3").sqrt(30), d("1e10").sqrt(5), d("Infinity").sqrt(5), d("1.44").sqrt(3), d("1.5").sqrt(2), d("0.0001").sqrt(3), d("123456789").sqrt(12))
["-1", "NaN", "-Infinity"].each do |x|
  begin
    d(x).sqrt(5)
  rescue FloatDomainError => e
    puts("FloatDomainError: #{e.message}")
  end
end
begin
  d("2").sqrt(-1)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# rounding: round(n, mode), floor, ceil, truncate, fix, frac
show("round", d("1.5").round, d("2.5").round, d("-2.5").round, d("1.25").round(1), d("1.35").round(1), d("1.25").round(1, :half_even), d("1.35").round(1, :half_even), d("1.25").round(1, :half_down), d("1.21").round(1, :up), d("1.29").round(1, :down), d("-1.21").round(1, :ceiling), d("-1.21").round(1, :floor), d("1.21").round(1, :truncate), d("1.25").round(1, :banker), d("1.25").round(1, :half_up), d("1.25").round(1, :default), d("-1.21").round(1, :ceil), d("1234.5").round(-2), d("1234.5").round(0), d("NaN").round(1), d("1.23").round(5), d("0.0049").round(2), d("-0.0049").round(2), d("99.99").round(1), d("0.5").round, d("-0.5").round, d("0.5").round(0, :half_even), d("1.5").round(0, :half_even))
p([d("1.5").round.to_i, d("-2.5").round.to_i, d("1234.5").round(-2).to_i])
show("floor", d("1.5").floor, d("-1.5").floor, d("1.5").ceil, d("-1.5").ceil, d("1.55").floor(1), d("1.55").ceil(1), d("-1.55").truncate(1), d("-1.55").truncate, d("15.5").truncate(-1), d("15.5").floor(-1), d("15.5").ceil(-1), d("1.5").fix, d("1.5").frac, d("-1.5").frac, d("15").frac, d("-0.5").fix, d("Infinity").floor(1), d("NaN").frac)
begin
  d("1.25").round(1, :bogus)
rescue ArgumentError => e
  puts("ArgumentError: #{e.message}")
end

# conversions
p([d("1.5").to_i, d("-1.5").to_i, d("1e30").to_i, d("0.001").to_i, d("99.9").to_int, d("-0").to_i])
p([d("1.5").to_f, d("1e400").to_f, d("-1e400").to_f, d("1e-400").to_f, d("0.1").to_f, d("Infinity").to_f, d("-0").to_f, d("123456789.125").to_f])
p(d("NaN").to_f.nan?)
p([d("1.5").to_r, d("0.001").to_r, d("100").to_r, d("-0.25").to_r, d("0").to_r])
["NaN", "Infinity", "-Infinity"].each do |x|
  begin
    d(x).to_i
  rescue FloatDomainError => e
    puts("FloatDomainError: #{e.message}")
  end
  begin
    d(x).to_r
  rescue FloatDomainError => e
    puts("FloatDomainError: #{e.message}")
  end
end
puts(s(d("1.5").to_d))

# parts: precision, scale, exponent, sign, n_significant_digits
["1.23", "100", "0.001", "1e10", "0", "-0", "NaN", "Infinity", "-12.340", "0.1", "123.456", "-Infinity", "2"].each do |x|
  v = d(x)
  puts("#{x}: precision=#{v.precision} scale=#{v.scale} exponent=#{v.exponent} sign=#{v.sign} nsd=#{v.n_significant_digits} ps=#{v.precision_scale.inspect}")
end
p(BigDecimal.double_fig)

# predicates
["1", "0", "-0", "NaN", "Infinity", "-Infinity", "-2"].each do |x|
  v = d(x)
  puts("#{x}: zero?=#{v.zero?} nan?=#{v.nan?} infinite?=#{v.infinite?.inspect} finite?=#{v.finite?} nonzero?=#{v.nonzero?.inspect} negative?=#{v.negative?} positive?=#{v.positive?}")
end

# comparison, with BigDecimal, Integer, Float, Rational, and NaN
p([d("1.5") <=> d("1.50"), d("1.5") == d("1.50"), d("1.5") <=> 2, d("1.5") <=> 1.5, d("NaN") <=> 1, d("NaN") == d("NaN"), d("Infinity") > 10 ** 100, d("1.5") < d("NaN"), d("0") == d("-0"), d("0") <=> d("-0"), d("1.5") == 1.5, d("1") == 1, d("1.5") <=> 3r / 2])
p([d("NaN") < 1, d("NaN") <= d("NaN"), d("Infinity") <=> d("Infinity"), d("-Infinity") < d("Infinity"), d("Infinity") == Float::INFINITY, d("1.5") != 2, d("1.5") != d("1.50"), d("2") >= d("2"), d("2") > d("2"), d("-3") <= d("-2.9"), d("1.5") <=> d("-Infinity"), d("0.1") == 0.1, d("1.5") == "1.5", d("1.5") <=> "1.5"])
p([d("3"), d("1.5"), d("-2"), d("-Infinity"), d("0")].sort.map { |x| s(x) })
mx = [d("3"), d("1.5")].max
p(s(mx)) if mx != nil
p([d("1.5"), d("2")].include?(d("2.0")))

# a computation: compound interest to the cent
balance = d("1000.00")
rate = d("0.05")
10.times { balance = (balance * (rate + 1)).round(2) }
puts(f(balance))
total = ["19.99", "5.01", "0.10", "0.20"].map { |x| d(x) }.reduce(d("0")) { |acc, x| acc + x }
puts(f(total))
