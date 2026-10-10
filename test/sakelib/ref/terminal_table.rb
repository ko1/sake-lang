# Reference implementation for test/sakelib/terminal_table.rb: a table renderer in plain Ruby after the
# terminal-table gem (Terminal::Table), with ascii, unicode and markdown borders. The style's border
# and alignment are keywords of new (the gem has style: {border:, alignment:}).

module Terminal
  class Table
    CHARS = {
      ascii: { h: "-", v: "|", top: ["+", "+", "+"], mid: ["+", "+", "+"], bottom: ["+", "+", "+"] },
      unicode: { h: "─", v: "│", top: ["┌", "┬", "┐"], mid: ["├", "┼", "┤"], bottom: ["└", "┴", "┘"] },
      markdown: { h: "-", v: "|", top: ["|", "|", "|"], mid: ["|", "|", "|"], bottom: ["|", "|", "|"] },
    }
    ALIGNMENTS = [:left, :right, :center]

    attr_reader :title, :headings, :rows, :border, :alignment

    def initialize(title: nil, headings: [], rows: [], border: :ascii, alignment: :left)
      raise ArgumentError, "unknown border style #{border.inspect}" unless CHARS.key?(border)
      raise ArgumentError, "unknown alignment #{alignment.inspect}" unless ALIGNMENTS.include?(alignment)
      raise ArgumentError, "markdown tables have no title" if border == :markdown && title
      @title, @headings, @rows, @border, @alignment = title, headings, rows.dup, border, alignment
      @aligns = {}
    end

    def add_row(row)
      @rows << row
      self
    end
    alias << add_row

    def add_separator
      @rows << :separator
      self
    end

    def align_column(i, a)
      raise ArgumentError, "unknown alignment #{a.inspect}" unless ALIGNMENTS.include?(a)
      @aligns[i] = a
      self
    end

    def number_of_columns = [*data_rows.map(&:size), @headings.size].max

    def to_s
      n = number_of_columns
      return "" if n == 0
      ws = widths(n)
      CHARS.fetch(@border) => { h:, v:, top:, mid:, bottom: }
      markdown = @border == :markdown
      out = []
      if @title
        inner = ws.sum + 3 * (n - 1)
        out << "#{top[0]}#{h * (inner + 2)}#{top[2]}"
        out << "#{v} #{@title.to_s.center(inner)} #{v}"
        out << rule(ws, mid, h)
      elsif !markdown
        out << rule(ws, top, h)
      end
      unless @headings.empty?
        out << line(ws, @headings, v)
        out << (markdown ? markdown_rule(ws) : rule(ws, mid, h))
      end
      @rows.each do |r|
        if r == :separator
          out << rule(ws, mid, h) unless markdown
        else
          out << line(ws, r, v)
        end
      end
      out << rule(ws, bottom, h) unless markdown
      out.join("\n")
    end

    private

    def data_rows = @rows.reject { |r| r == :separator }
    def cells(row, n) = (0...n).map { |i| row.fetch(i, "").to_s }

    def widths(n)
      ws = Array.new(n, 0)
      [@headings, *data_rows].each do |r|
        cells(r, n).each_with_index { |c, i| ws[i] = [ws[i], c.size].max }
      end
      if @title
        extra = @title.to_s.size - (ws.sum + 3 * (n - 1))
        ws[n - 1] += extra if extra > 0
      end
      ws
    end

    def column_alignment(i) = @aligns[i] || @alignment

    def align(s, w, a)
      case a
      when :left then s.ljust(w)
      when :right then s.rjust(w)
      else s.center(w)
      end
    end

    def rule(ws, ends, h) = "#{ends[0]}#{ws.map { |w| h * (w + 2) }.join(ends[1])}#{ends[2]}"

    def line(ws, row, v)
      parts = cells(row, ws.size).each_with_index.map { |c, i| " #{align(c, ws[i], column_alignment(i))} " }
      "#{v}#{parts.join(v)}#{v}"
    end

    def markdown_rule(ws)
      parts = ws.each_with_index.map do |w, i|
        case column_alignment(i)
        when :left then ":#{"-" * (w + 1)}"
        when :right then "#{"-" * (w + 1)}:"
        else ":#{"-" * w}:"
        end
      end
      "|#{parts.join("|")}|"
    end
  end
end
