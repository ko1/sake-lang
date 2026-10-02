# Print a reproducible random sample of classified errors with source context, for hand checking.
# usage: ruby sample.rb CAUSE N [SEED]
EXP = File.expand_path("../..", __dir__)
cause, n, seed = ARGV[0], ARGV[1].to_i, (ARGV[2] || 1).to_i
rows = File.readlines(File.join(__dir__, "classified.tsv")).drop(1).map { _1.chomp.split("\t") }.select { _1[4] == cause }
rows.sample(n, random: Random.new(seed)).each do |path, err, *|
  l = err[/\A\((\d+)/, 1].to_i
  src = File.readlines(File.join(EXP, path))
  puts "=== #{path} #{err}"
  ([l - 3, 1].max..[l + 1, src.size].min).each { |i| puts "#{i == l ? ">" : " "}#{i.to_s.rjust(4)} #{src[i - 1]}" }
end
