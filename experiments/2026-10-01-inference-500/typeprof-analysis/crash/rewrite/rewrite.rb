# Rewrite `.sort_by/min_by/max_by { |a, b| body }` into `{ |e__| a, b = e__; body }` (same Ruby semantics).
src = File.read(ARGV[0])
out = src.gsub(/\.(sort_by|min_by|max_by) \{ \|([^|,]+),\s*([^|]+)\|/) { ".#{$1} { |e__| #{$2}, #{$3} = e__;" }
File.write(ARGV[1], out)
