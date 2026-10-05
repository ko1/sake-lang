class FormulaError < StandardError
  attr_reader :formula

  def initialize(message, formula)
    super(message)
    @formula = formula
  end
end

MASSES = {
  "H" => 1.008, "C" => 12.011, "N" => 14.007, "O" => 15.999, "Na" => 22.990, "Mg" => 24.305,
  "S" => 32.06, "Cl" => 35.45, "K" => 39.098, "Ca" => 40.078, "Fe" => 55.845, "Cu" => 63.546, "P" => 30.974
}.freeze

def read_count(s, pos)
  m = (s[pos..] || "").match(/\A\d+/)
  return [1, pos] unless m
  [m.to_s.to_i, pos + m.to_s.size]
end

def merge_into(target, counts, times)
  counts.each { |el, n| target[el] = target.fetch(el, 0) + n * times }
end

def parse_group(s, pos, close)
  counts = {}
  while pos < s.size
    c = s[pos]
    if c == close
      return [counts, pos + 1]
    elsif c == "(" || c == "["
      inner, pos = parse_group(s, pos + 1, c == "(" ? ")" : "]")
      n, pos = read_count(s, pos)
      merge_into(counts, inner, n)
    elsif c.match?(/[A-Z]/)
      el = s[pos..][/\A[A-Z][a-z]?/]
      raise FormulaError.new("unknown element #{el}", s) unless MASSES.key?(el)
      n, pos = read_count(s, pos + el.size)
      counts[el] = counts.fetch(el, 0) + n
    else
      raise FormulaError.new("unexpected '#{c}' at #{pos}", s)
    end
  end
  raise FormulaError.new("missing '#{close}'", s) if close != ""
  [counts, pos]
end

def parse_formula(text)
  text.split("*").each_with_object({}) do |part, total|
    n, pos = read_count(part, 0)
    counts, _rest = parse_group(part, pos, "")
    raise FormulaError.new("empty formula", text) if counts.empty?
    merge_into(total, counts, n)
  end
end

def molar_mass(counts) = counts.sum { |el, n| MASSES[el] * n }

def show_counts(counts)
  counts.sort_by { |el, _| el }.map { |el, n| n == 1 ? el : "#{el}#{n}" }.join(" ")
end

def side_counts(side)
  side.split("+").each_with_object({}) do |term, total|
    m = term.strip.match(/\A(\d*)\s*(.+)\z/)
    coef = m[1].empty? ? 1 : m[1].to_i
    merge_into(total, parse_formula(m[2]), coef)
  end
end

def check_reaction(eq)
  lhs, rhs = eq.split("->")
  left = side_counts(lhs)
  right = side_counts(rhs)
  elements = (left.keys | right.keys).sort
  bad = elements.reject { |el| left.fetch(el, 0) == right.fetch(el, 0) }
  if bad.empty?
    "balanced"
  else
    "unbalanced: " + bad.map { |el| "#{el} #{left.fetch(el, 0)}->#{right.fetch(el, 0)}" }.join(", ")
  end
end

formulas = ["H2O", "C6H12O6", "Mg(OH)2", "K4[Fe(CN)6]", "CuSO4*5H2O", "Ca3(PO4)2", "NaCl",
            "Xy2", "H2(O", "2", "Fe2O3)"]
formulas.each do |f|
  counts = parse_formula(f)
  puts format("%-12s %-22s %9.3f g/mol", f, show_counts(counts), molar_mass(counts))
rescue FormulaError => e
  puts format("%-12s error: %s", f, e.message)
end

reactions = ["2H2 + O2 -> 2H2O", "CH4 + 2O2 -> CO2 + 2H2O", "Fe + O2 -> Fe2O3",
             "4Fe + 3O2 -> 2Fe2O3", "C6H12O6 + 6O2 -> 6CO2 + 6H2O", "NaOH + HCl -> NaCl + H2O + O"]
reactions.each { |r| puts "#{r}: #{check_reaction(r)}" }
