# Evaluate a small spreadsheet whose formulas can fail; errors become cell values like #DIV/0! and propagate.
require "set"

class CellError < StandardError
  attr_reader :code

  def initialize(message, code)
    super(message)
    @code = code
  end
end

class Sheet
  attr_reader :cells, :cache, :evaluating

  def initialize(cells, cache, evaluating)
    @cells = cells
    @cache = cache
    @evaluating = evaluating
  end
end

SHEET_CELLS = {
  "A1" => "10", "A2" => "32", "A3" => "hello", "A4" => "=A1+A2",
  "B1" => "=A4/A1", "B2" => "=A1/C1", "B3" => "=B2+1", "B4" => "=SUM(A1:A2)",
  "C1" => "0", "C2" => "=A3*2", "C3" => "=Z9+1", "C4" => "=SUM(A1:A4)",
  "D1" => "=D2+1", "D2" => "=D1*2", "D3" => "=MAX(A1:A2)-MIN(A1:A2)", "D4" => "=AVG(C1:C1)",
  "E1" => "=SUM(A1:B1)", "E2" => "=AVG(A1:A2)", "E3" => "=FOO(A1:A2)", "E4" => "=A1+"
}

def cell_value(sheet, ref)
  return sheet.cache[ref] if sheet.cache.key?(ref)
  raw = sheet.cells[ref] or raise CellError.new("unknown cell #{ref}", "#REF!")
  raise CellError.new("cycle through #{ref}", "#CYCLE!") if sheet.evaluating.include?(ref)
  sheet.evaluating << ref
  value = begin
    if raw.start_with?("=")
      eval_formula(sheet, raw.delete_prefix("="))
    elsif raw.match?(/\A-?\d+(\.\d+)?\z/)
      Float(raw)
    else
      raw
    end
  rescue CellError => e
    e.code
  ensure
    sheet.evaluating.delete(ref)
  end
  sheet.cache[ref] = value
end

def number(sheet, ref)
  v = cell_value(sheet, ref)
  return v if v.is_a?(Float)
  raise CellError.new("error in #{ref}", v) if v.start_with?("#")
  raise CellError.new("#{ref} is text", "#VALUE!")
end

def expand(range)
  m = range.match(/\A([A-Z])(\d+):([A-Z])(\d+)\z/) or raise CellError.new("bad range #{range}", "#REF!")
  rows = (m[2].to_i..m[4].to_i).to_a
  (m[1]..m[3]).flat_map { |c| rows.map { |r| "#{c}#{r}" } }
end

def call_function(sheet, name, range)
  values = expand(range).map { |ref| number(sheet, ref) }
  case name
  when "SUM" then values.sum
  when "MAX" then values.max
  when "MIN" then values.min
  when "AVG"
    raise CellError.new("empty range", "#DIV/0!") if values.empty?
    values.sum / values.size
  else
    raise CellError.new("unknown function #{name}", "#NAME?")
  end
end

def operand(sheet, text)
  if (m = text.match(/\A([A-Z]+)\(([A-Z0-9:]+)\)\z/))
    return call_function(sheet, m[1], m[2])
  end
  return number(sheet, text) if text.match?(/\A[A-Z]\d+\z/)
  return Float(text) if text.match?(/\A\d+(\.\d+)?\z/)
  raise CellError.new("cannot read '#{text}'", "#VALUE!")
end

def eval_formula(sheet, expr)
  m = expr.match(%r{\A(.+?)([-+*/])(.*)\z})
  return operand(sheet, expr) unless m
  left = operand(sheet, m[1])
  right = operand(sheet, m[3])
  case m[2]
  when "+" then left + right
  when "-" then left - right
  when "*" then left * right
  when "/"
    raise CellError.new("division by zero", "#DIV/0!") if right == 0.0
    left / right
  end
end

sheet = Sheet.new(SHEET_CELLS, {}, Set[])
%w[A B C D E].each do |col|
  row = (1..4).map do |r|
    v = cell_value(sheet, "#{col}#{r}")
    s = v.is_a?(Float) ? v.round(2).to_s : v
    s.ljust(9)
  end
  puts "#{col} | #{row.join(" ").rstrip}"
end
errors = sheet.cache.select { |_, v| v.is_a?(String) && v.start_with?("#") }
puts "#{errors.size} error cells: #{errors.sort_by { |ref, _| ref }.map { |ref, v| "#{ref}=#{v}" }.join(" ")}"
