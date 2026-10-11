require "rainbow"

# the test's output is not a terminal, so colouring starts disabled
p(Rainbow.enabled)
p(Rainbow("plain").red)
Rainbow.enabled = true
p(Rainbow.enabled)

# colours and effects, chained
p(Rainbow("text").red)
p(Rainbow("text").red.bright)
p(Rainbow("text").bright.red)
p(Rainbow("text").green.underline.italic)
p(Rainbow("text").blue.background(:yellow))
p(Rainbow("text").bg(:white).fg(:black))
p([Rainbow("a").black, Rainbow("a").yellow, Rainbow("a").magenta, Rainbow("a").cyan, Rainbow("a").white])
p([Rainbow("e").faint, Rainbow("e").dark, Rainbow("e").bold, Rainbow("e").blink])
p([Rainbow("e").inverse, Rainbow("e").hide, Rainbow("e").cross_out, Rainbow("e").strike, Rainbow("e").reset])

# colour forms: index, name, RGB, hex, X11 name
p(Rainbow("i").color(5))
p(Rainbow("n").color(:default))
p(Rainbow("rgb").color(255, 128, 0))
p(Rainbow("rgb").background(0, 0, 255))
p(Rainbow("hex").color("#ff8800"))
p(Rainbow("hex").color("00FF00"))
p(Rainbow("x11").color(:aqua))
p(Rainbow("x11").background(:lightgoldenrod))
p(Rainbow("x11").foreground(:greenyellow))

# non-strings are converted; colouring the empty string still wraps it
p(Rainbow(42).red)
p(Rainbow("").red)

# uncolor removes every SGR sequence
s = Rainbow("hello").red.bright.underline
puts(s.inspect)
p(Rainbow.uncolor(s))
p(Rainbow.uncolor("no codes"))
p(s.length)

# errors
begin
  Rainbow("x").color(:no_such_colour)
rescue ArgumentError => e
  puts(e.message[0, 60])
end
begin
  Rainbow("x").color(1, 2)
rescue ArgumentError => e
  puts(e.message)
end
begin
  Rainbow("x").color("#xyz")
rescue ArgumentError => e
  puts(e.message)
end
begin
  Rainbow("x").color(256, 0, 0)
rescue ArgumentError => e
  puts(e.message)
end

# disabled again: everything is the plain text
Rainbow.enabled = false
p(Rainbow("off").red.bright)
p(Rainbow("off").color(1, 2, 3))
