# Reference implementation for test/sakelib/colorize.rb: the colorize gem's String methods in plain
# Ruby (the gem is not installed here), after colorize 1.1.0's instance_methods.rb / class_methods.rb:
# "x".red => "\e[0;31;49mx\e[0m"; a second call re-parses the codes and merges ("x".red.on_blue =>
# "\e[0;31;44mx\e[0m"); String.disable_colorization = true makes every call return the String as is.

module Colorize
  COLOR_CODES = {
    black: 0, light_black: 60, red: 1, light_red: 61, green: 2, light_green: 62,
    yellow: 3, light_yellow: 63, blue: 4, light_blue: 64, magenta: 5, light_magenta: 65,
    cyan: 6, light_cyan: 66, white: 7, light_white: 67, default: 9,
  }
  MODE_CODES = {
    default: 0, bold: 1, dim: 2, italic: 3, underline: 4, blink: 5, blink_slow: 5, blink_fast: 6,
    invert: 7, hide: 8, strike: 9,
  }

  module ClassMethods
    def color_codes = COLOR_CODES
    def mode_codes = MODE_CODES
    def colors = color_codes.keys
    def modes = mode_codes.keys
    def color(c) = (color_codes[c] + 30 if color_codes[c])
    def background_color(c) = (color_codes[c] + 40 if color_codes[c])
    def mode(m) = mode_codes[m]

    def disable_colorization(value = nil)
      @disable_colorization = value unless value.nil?
      @disable_colorization || false
    end

    def disable_colorization=(value)
      @disable_colorization = value
    end

    def add_color_alias(*params)
      params = params.flatten
      params.each_slice(2) do |name, source|
        raise "Color #{name} already exists" if color_codes.key?(name)
        raise "Color #{source} does not exist" unless color_codes.key?(source)
        color_codes[name] = color_codes[source]
      end
    end
  end

  module InstanceMethods
    def colorize(params)
      return self if self.class.disable_colorization
      scan_for_colors.inject(self.class.new) do |str, match|
        colors_from_params(match, params)
        defaults_colors(match)
        str << "\033[#{match[0]};#{match[1]};#{match[2]}m#{match[3]}\033[0m"
      end
    end

    def uncolorize
      scan_for_colors.inject(self.class.new) { |str, match| str << match[3] }
    end

    def colorized?
      scan_for_colors.inject([]) { |colors, match| colors << match.tap(&:pop) }.flatten.compact.any?
    end

    private

    def scan_for_colors
      scan(/\033\[([0-9;]+)m(.+?)\033\[0m|([^\033]+)/m).map { |match| split_colors(match) }
    end

    def split_colors(match)
      colors = (match[0] || "").split(";")
      Array.new(4).tap do |array|
        array[0], array[1], array[2] = colors if colors.length == 3
        array[1] = colors if colors.length == 1
        array[3] = match[1] || match[2]
      end
    end

    def defaults_colors(match)
      match[0] ||= self.class.mode(:default)
      match[1] ||= self.class.color(:default)
      match[2] ||= self.class.background_color(:default)
    end

    def colors_from_params(match, params)
      case params
      when Hash
        match[0] = self.class.mode(params[:mode]) if self.class.mode(params[:mode])
        match[1] = self.class.color(params[:color]) if self.class.color(params[:color])
        match[2] = self.class.background_color(params[:background]) if self.class.background_color(params[:background])
      when Symbol
        match[1] = self.class.color(params) if self.class.color(params)
      end
    end
  end
end

class String
  extend Colorize::ClassMethods
  include Colorize::InstanceMethods

  Colorize::COLOR_CODES.each_key do |c|
    define_method(c) { colorize(color: c) }
    define_method(:"on_#{c}") { colorize(background: c) }
  end
  Colorize::MODE_CODES.each_key do |m|
    define_method(m) { colorize(mode: m) } unless m == :default
  end
end
