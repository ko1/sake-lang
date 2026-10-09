require_relative "ref/colorize"

# one colour, a background, a mode
p "x".red
p "x".on_blue
p "x".bold
p "x".red.on_blue
p "x".red.on_blue.bold
p "x".light_yellow.on_light_black.underline

# colorize with a Symbol or a Hash
p "hello".colorize(:light_cyan)
p "hello".colorize(color: :green, background: :black, mode: :underline)
p "hello".colorize(color: :yellow, mode: :italic)
p "hello".colorize(background: :magenta)
p "hello".colorize(color: :red, mode: :dim)
p "x".red.colorize(background: :white)

# a String with plain and coloured runs: each run keeps its own codes
s = "plain " + "red".red + " and " + "green".on_green + " end"
p s
p s.bold
p s.blue
p s.bold.uncolorize
p "nothing".uncolorize
p s.colorized?
p "nothing".colorized?
p "".colorized?
p "".red
p "two\nlines".underline

# an unknown name keeps what is there
p "x".colorize(:nope)
p "x".red.colorize(color: :nope, mode: :blink)

# the tables
p String.colors
p String.modes
p String.color(:red)
p String.background_color(:light_red)
p String.mode(:bold)
p String.color(:nope)
String.colors.each { |c| p c.to_s.colorize(color: c) }
String.modes.each { |m| p m.to_s.colorize(mode: m) }
p ["1".light_black, "2".on_light_white, "3".invert, "4".strike, "5".default, "6".on_default]

# an alias
String.add_color_alias(:grey, :light_black)
p "x".colorize(:grey)
p "x".colorize(background: :grey)
begin
  String.add_color_alias(:grey, :red)
rescue RuntimeError => e
  puts e.message
end
begin
  String.add_color_alias(:pink, :rose)
rescue RuntimeError => e
  puts e.message
end

# switching colours off
p String.disable_colorization
String.disable_colorization = true
p String.disable_colorization
p "x".red
p "x".colorize(color: :red, mode: :bold)
String.disable_colorization(false)
p "x".red
