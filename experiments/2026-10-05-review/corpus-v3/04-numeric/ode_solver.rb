class State
  attr_accessor :t, :y

  def initialize(t, y)
    @t = t
    @y = y
  end
end

def add_scaled(y, h, k)
  y.each_index.map { |i| y[i] + h * k[i] }
end

def euler_step(t, y, h)
  k = yield(t, y)
  add_scaled(y, h, k)
end

def midpoint_step(t, y, h)
  k1 = yield(t, y)
  k2 = yield(t + h / 2.0, add_scaled(y, h / 2.0, k1))
  add_scaled(y, h, k2)
end

def rk4_step(t, y, h)
  k1 = yield(t, y)
  k2 = yield(t + h / 2.0, add_scaled(y, h / 2.0, k1))
  k3 = yield(t + h / 2.0, add_scaled(y, h / 2.0, k2))
  k4 = yield(t + h, add_scaled(y, h, k3))
  y.each_index.map { |i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
end

def integrate(method, y0, t0, t1, steps, &f)
  h = (t1 - t0) / steps
  s = State.new(t0, y0)
  steps.times do
    s.y = case method
          in :euler then euler_step(s.t, s.y, h, &f)
          in :midpoint then midpoint_step(s.t, s.y, h, &f)
          in :rk4 then rk4_step(s.t, s.y, h, &f)
          end
    s.t += h
  end
  s
end

def oscillator(t, y) = [y[1], -y[0]]
def energy(y) = 0.5 * (y[0] ** 2 + y[1] ** 2)

methods = [:euler, :midpoint, :rk4]

puts "harmonic oscillator, t = 0..10, y(0) = [1, 0]"
methods.each do |m|
  [50, 100, 200].each do |n|
    s = integrate(m, [1.0, 0.0], 0.0, 10.0, n) { |t, y| oscillator(t, y) }
    y = s.y
    err = (y[0] - Math.cos(10.0)).abs
    puts format("  %-8s n=%3d x=%+.6f err=%.3e energy drift=%+.3e", m, n, y[0], err, energy(y) - 0.5)
  end
end

puts "logistic growth r=0.8 K=100, y(0)=5"
exact = 100.0 / (1.0 + 19.0 * Math.exp(-0.8 * 12.0))
methods.each do |m|
  s = integrate(m, [5.0], 0.0, 12.0, 60) { |t, y| [0.8 * y[0] * (1.0 - y[0] / 100.0)] }
  puts format("  %-8s y(12)=%.6f exact=%.6f", m, s.y[0], exact)
end

puts "Lotka-Volterra predator/prey (rk4, h=0.05)"
s = State.new(0.0, [40.0, 9.0])
peaks = []
prev_prey = 40.0
rising = false
3000.times do
  t = s.t
  y = rk4_step(t, s.y, 0.05) { |tt, v| [0.1 * v[0] - 0.02 * v[0] * v[1], 0.01 * v[0] * v[1] - 0.1 * v[1]] }
  s.y = y
  s.t = t + 0.05
  if rising && y[0] < prev_prey
    peaks << [t, prev_prey]
    rising = false
  elsif !rising && y[0] > prev_prey
    rising = true
  end
  prev_prey = y[0]
end
peaks.each { |t, v| puts format("  prey peak %.2f at t=%.2f", v, t) }
final = s.y
puts format("  at t=%.1f prey=%.3f predators=%.3f", s.t, final[0], final[1])

puts "convergence order (rk4 on y' = -2ty, y(0)=1, t=0..1)"
prev_err = nil
[5, 10, 20, 40].each do |n|
  st = integrate(:rk4, [1.0], 0.0, 1.0, n) { |t, y| [-2.0 * t * y[0]] }
  err = (st.y[0] - Math.exp(-1.0)).abs
  order = prev_err ? Math.log2(prev_err / err) : 0.0
  puts format("  n=%2d err=%.3e observed order=%.2f", n, err, order)
  prev_err = err
end
