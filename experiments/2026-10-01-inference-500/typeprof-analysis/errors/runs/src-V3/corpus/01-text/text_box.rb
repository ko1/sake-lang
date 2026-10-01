class BoxOptions
  attr_reader :style, :padding, :align, :title, :shadow, :max_width

  def initialize(style, padding, align, title, shadow, max_width)
    @style = style
    @padding = padding
    @align = align
    @title = title
    @shadow = shadow
    @max_width = max_width
  end
end

def border(style)
  case style
  when :ascii then { h: "-", v: "|", tl: "+", tr: "+", bl: "+", br: "+" }
  when :double then { h: "=", v: "#", tl: "#", tr: "#", bl: "#", br: "#" }
  when :rounded then { h: "-", v: "|", tl: ".", tr: ".", bl: "'", br: "'" }
  when :stars then { h: "*", v: "*", tl: "*", tr: "*", bl: "*", br: "*" }
  end
end

def wrap(text, width)
  lines = []
  text.split("\n").each do |para|
    line = +""
    para.split(" ").each do |w|
      if line.empty?
        line = +w
      elsif line.size + 1 + w.size <= width
        line << " " << w
      else
        lines << line
        line = +w
      end
    end
    lines << line
  end
  lines
end

def place(s, width, align)
  case align
  when :left then s.ljust(width)
  when :right then s.rjust(width)
  when :center then s.center(width)
  end
end

def box(text, opts)
  border(opts.style) => { h:, v:, tl:, tr:, bl:, br: }
  pad = opts.padding
  lines = wrap(text, opts.max_width)
  title = opts.title
  inner = lines.map(&:size).max
  inner = title.size + 2 if title && title.size + 2 > inner
  full = inner + pad * 2
  top =
    if title.nil?
      tl + h * full + tr
    else
      label = " #{title} "
      left = (full - label.size) / 2
      tl + h * left + label + h * (full - left - label.size) + tr
    end
  out = [top]
  blank = v + " " * full + v
  (pad / 2).times { out << blank }
  lines.each { |l| out << v + " " * pad + place(l, inner, opts.align) + " " * pad + v }
  (pad / 2).times { out << blank }
  out << bl + h * full + br
  if opts.shadow
    out = out.each_with_index.map { |l, i| i == 0 ? l + " " : l + ":" }
    out << " " + ":" * (full + 2)
  end
  out
end

def side_by_side(left, right, gap)
  width = left.map(&:size).max
  rows = [left.size, right.size].max
  (0...rows).map do |i|
    (left[i].to_s.ljust(width) + " " * gap + right[i].to_s).rstrip
  end
end

message = "Sake writes the type on every operation. The program says which code runs, and the checker can see it."
puts box(message, BoxOptions.new(:ascii, 1, :left, nil, false, 30)).join("\n")
puts box(message, BoxOptions.new(:double, 2, :center, "NOTICE", true, 24)).join("\n")
a = box("left\nside", BoxOptions.new(:rounded, 1, :right, nil, false, 20))
b = box("A longer note that wraps over lines.", BoxOptions.new(:stars, 2, :left, "tip", false, 14))
side_by_side(a, b, 3).each { |l| puts l }
puts box("x", BoxOptions.new(:ascii, 0, :left, "a very long title", false, 10)).join("\n")
