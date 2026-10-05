# frozen_string_literal: true

# What kinds of union types remain, from measure.rb's detail (sake.jsonl[.gz] of a results directory).
# usage: ruby union_kinds.rb RESULTS_DIR
# Each non-mono unit of class "union" is put in one kind, by its shown type (first match wins):
#   numeric      only numbers mixed (Integer | Float, Integer | Rational) at the top or inside
#   struct       two or more of the program's types (Circle | Square)
#   tuple-tag    Tuples of different shapes ([:add, Integer] | [:neg])
#   scalar-mix   different scalar types (Integer | String, Symbol | String)
#   container    a container whose elements are a union of the kinds above
require "json"
require "zlib"

dir = ARGV[0]
path = File.exist?(File.join(dir, "sake.jsonl")) ? File.join(dir, "sake.jsonl") : File.join(dir, "sake.jsonl.gz")
lines = path.end_with?(".gz") ? Zlib::GzipReader.open(path, &:readlines) : File.readlines(path)
SCALARS = %w[Integer Float Rational Complex String Symbol true|false Regexp Time Range MatchData].freeze
NUM = %w[Integer Float Rational Complex].freeze

def kind(show)
  top = show.split(/\s*\|\s*(?![^\[]*\])/).map(&:strip).reject { _1 == "nil" }
  names = top.map { _1.sub(/@.*/, "").sub(/\[.*/, "") }
  return "numeric" if names.size > 1 && names.all? { NUM.include?(_1) }
  return "tuple-tag" if names.size > 1 && top.all? { _1.start_with?("[") }
  return "struct" if names.size > 1 && names.all? { _1.match?(/\A[A-Z]/) && !SCALARS.include?(_1) && !%w[Array Hash Set Tuple].include?(_1) }
  return "scalar-mix" if names.size > 1
  return "numeric" if show.match?(/(Integer \| Float|Float \| Integer|Integer \| Rational|Rational \| Integer)/)
  "container"
end

tally = Hash.new { |h, k| h[k] = Hash.new(0) }
lines.each do |l|
  j = JSON.parse(l)
  (j["detail"] || []).each do |unit, _line, _name, c, show|
    next unless c == "union"
    group = unit.start_with?("sig") ? unit : "expr"
    tally[group][kind(show)] += 1
  end
end
kinds = %w[numeric struct tuple-tag scalar-mix container]
puts "| unit | #{kinds.join(" | ")} | total |"
puts "|---|#{"---|" * (kinds.size + 1)}"
tally.sort.each { |u, h| puts "| #{u} | #{kinds.map { h[_1] }.join(" | ")} | #{h.values.sum} |" }
