# Counts Spinel's widened (poly) sites in an --emit-types JSON, by where the code lives.
# ruby classify.rb TYPES.json [--files] [--examples N]
#   TYPES.json: `spinel ... main.rb --emit-types` over the roundhouse tree with the
#   #<SPINEL_SOURCE> markers turned into plain comments, so each position is the emitted file's own.
# Categories (by the emitted file's path):
#   app      the transpiled app: app/ config/ db/ main.rb boot.rb (models, controllers, views, routes,
#            and what roundhouse synthesizes for them: *_row.rb, *_params.rb, route_helpers.rb, views.rb)
#   runtime  roundhouse's Rails replacement: runtime/ (active_record, action_*, tep server, ...)
#   spinel   Spinel's own library: builtins/ and packages/ (set, json, openssl, cgi, ...)
#   gem      spin packages fetched for the app (~/.cache/spin/packages: bcrypt)
# Counts:
#   widen    --warn-widen diagnostics: a parameter or return slot widened to untyped (boxed poly)
#   unbound  of those, "never bound: no call site gives it a type" (dead code in this program)
#   def_w    DefNodes whose signature has "widened":true
#   defs     all DefNodes
#   poly_n   typed nodes whose type is poly or a container of poly (poly, poly_array, *_poly_hash)
#   nodes    all typed nodes
require "json"

path = ARGV.shift or abort "usage: classify.rb TYPES.json [--files] [--examples N]"
files = ARGV.delete("--files")
ex = (i = ARGV.index("--examples")) ? ARGV[i + 1].to_i : 0
j = JSON.parse(File.read(path))

def rel(f)
  f.sub(%r{.*/spinel/bin/\.\./}, "spinel:").sub(%r{.*/\.cache/spin/packages/}, "gem:").sub(%r{.*/out-[a-z]+/}, "")
end

def cat(f)
  r = rel(f)
  case r
  when /\Aspinel:/ then "spinel"
  when /\Agem:/ then "gem"
  when %r{\Aruntime/} then "runtime"
  when %r{\A(app|config|db)/}, "main.rb", "boot.rb" then "app"
  else raise "unclassified file: #{f}"
  end
end

def sub(f)
  r = rel(f)
  case cat(f)
  when "app" then r[%r{\Aapp/(models|controllers|views)}] || r
  when "runtime" then r.split("/")[0, 2].join("/").sub(/\.rb\z/, "")
  else r.split("/")[0, 2].join("/")
  end
end

poly_t = /\A(poly|poly_array|.*_poly_hash|poly_.*_hash)\z/
rows = Hash.new { |h, k| h[k] = Hash.new(0) }
add = ->(f, key) { rows[cat(f)][key] += 1; rows["#{cat(f)} #{sub(f)}"][key] += 1; rows["total"][key] += 1; rows["file #{rel(f)}"][key] += 1 }
unbound = ->(d) { (d["why"] || []).any? { |w| w["note"].to_s.include?("never bound") } }

j["diagnostics"].each do |d|
  next unless d["message"].to_s.include?("widened")
  add.(d["file"], "widen")
  add.(d["file"], "unbound") if unbound.(d)
end
j["types"].each do |t|
  add.(t["file"], "nodes")
  add.(t["file"], "poly_n") if t["type"] =~ poly_t
  next unless t["kind"] == "DefNode"
  add.(t["file"], "defs")
  add.(t["file"], "def_w") if t["widened"]
end

cols = %w[widen unbound def_w defs poly_n nodes]
puts format("%-58s %s", "where", cols.map { |c| format("%7s", c) }.join)
order = ->(k) { [k == "total" ? 2 : 0, k.start_with?("file ") ? 1 : 0, k] }
rows.keys.sort_by(&order).each do |k|
  next if k.start_with?("file ") && !files
  v = rows[k]
  puts format("%-58s %s", k, cols.map { |c| format("%7d", v[c]) }.join)
end

if ex > 0
  %w[app runtime gem].each do |c|
    puts "\n# examples: #{c} (widened, not 'never bound')"
    j["diagnostics"].select { |d| d["message"].to_s.include?("widened") && cat(d["file"]) == c && !unbound.(d) }
      .first(ex).each { |d| puts "#{rel(d["file"])}:#{d["line"]}: #{d["message"].sub(/\ASpinel: /, "")}" }
  end
end
