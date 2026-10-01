class Cpx
  attr_reader :re, :im

  def initialize(re, im)
    @re = re
    @im = im
  end

  def self.polar(r, theta) = new(r * Math.cos(theta), r * Math.sin(theta))
  def +(b) = Cpx.new(@re + b.re, @im + b.im)
  def -(b) = Cpx.new(@re - b.re, @im - b.im)

  def *(b)
    case b
    in Cpx then Cpx.new(@re * b.re - @im * b.im, @re * b.im + @im * b.re)
    in Float then Cpx.new(@re * b, @im * b)
    end
  end

  def abs = Math.hypot(@re, @im)
  def conj = Cpx.new(@re, -@im)
  def to_s = format("%.3f%+.3fi", @re, @im)
end

def dft(xs)
  n = xs.size
  (0...n).map do |k|
    acc = Cpx.new(0.0, 0.0)
    xs.each_with_index do |x, t|
      acc += x * Cpx.polar(1.0, -2.0 * Math::PI * k * t / n)
    end
    acc
  end
end

def fft(xs)
  n = xs.size
  return xs if n == 1
  raise ArgumentError, "length #{n} is not a power of two" if n.odd?
  ev, od = xs.each_with_index.partition { |x, i| i.even? }.map { |pairs| pairs.map(&:first) }
  e = fft(ev)
  o = fft(od)
  out = xs.dup
  (0...(n / 2)).each do |k|
    tw = Cpx.polar(1.0, -2.0 * Math::PI * k / n) * o[k]
    out[k] = e[k] + tw
    out[k + n / 2] = e[k] - tw
  end
  out
end

def inverse_fft(spec)
  n = spec.size
  fft(spec.map(&:conj)).map { |c| c.conj * (1.0 / n) }
end

n = 64
rate = 64.0
signal = (0...n).map do |i|
  t = i / rate
  v = 1.5 * Math.sin(2.0 * Math::PI * 5.0 * t) + 0.8 * Math.cos(2.0 * Math::PI * 12.0 * t) + 0.3 * Math.sin(2.0 * Math::PI * 20.0 * t + 0.7) + 0.25
  Cpx.new(v, 0.0)
end

slow = dft(signal)
fast = fft(signal)
diff = slow.zip(fast).map { |s, f| (s - f).abs }.max
puts format("max |DFT - FFT| = %.2e", diff)

amps = (0..(n / 2)).map do |k|
  scale = (k == 0 || k == n / 2) ? 1.0 / n : 2.0 / n
  [k * rate / n, fast[k].abs * scale]
end
peaks = amps.select { |f, a| a > 0.1 }
puts "components above 0.1:"
peaks.sort_by { |f, a| -a }.each { |f, a| puts format("  %5.1f Hz amplitude %.4f", f, a) }
dc_f, dc_a = amps[0]
puts format("DC offset %.4f", dc_a)
puts "bin 12 = #{fast[12]}"

energy_time = signal.sum { |c| c.re ** 2 }
energy_freq = fast.map { |c| c.abs ** 2 }.sum / n
puts format("Parseval: time %.6f freq %.6f", energy_time, energy_freq)

back = inverse_fft(fast)
err = back.zip(signal).map { |b, s| (b - s).abs }.max
puts format("round trip error %.2e", err)

# low-pass: zero bins above 10 Hz, transform back, compare with the pure 5 Hz part + DC
filtered = (0...n).map do |k|
  freq = k <= n / 2 ? k : n - k
  freq * rate / n > 10.0 ? Cpx.new(0.0, 0.0) : fast[k]
end
smooth = inverse_fft(filtered)
worst = 0.0
smooth.each_with_index do |c, i|
  want = 1.5 * Math.sin(2.0 * Math::PI * 5.0 * i / rate) + 0.25
  worst = [worst, (c.re - want).abs].max
end
puts format("low-pass max deviation from 5 Hz + DC: %.2e", worst)

begin
  fft(signal.take(12))
rescue ArgumentError => e
  puts "fft refused: #{e.message}"
end
