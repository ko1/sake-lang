# Counterfactual runs of TypeProf over the programs that had errors in results-head.
# usage: ruby driver.rb VARIANT    (writes runs/VARIANT.jsonl; one typeprof at a time, 120 s / 3 GB each)
# A variant is a set of TypeProf monkey patches (patches/*.rb) plus source rewrites (rewrite.rb),
# applied to a scratch copy of each program; the corpus is never modified.
require "json"
require "zlib"
require "open3"
require "fileutils"
require_relative "rewrite"

EXP = File.expand_path("../..", __dir__)
TYPEPROF = Gem.bin_path("typeprof", "typeprof")
VARIANTS = {
  "V0" => [[], []],                                                     # harness check: must equal results-head
  "V1" => [%w[interface], []],
  "V2" => [%w[interface numeric_catchall], []],
  "V3" => [%w[interface numeric_catchall masgn], []],
  "V4" => [%w[interface numeric_catchall masgn], %i[nilq]],
  "V5" => [%w[interface numeric_catchall masgn], %i[nilq acond]],
  "V6" => [%w[interface numeric_catchall masgn rbs_nonnil], %i[nilq acond]],
  "V7" => [%w[interface numeric_catchall masgn rbs_nonnil nil_literal], %i[nilq acond]],
}
name = ARGV.fetch(0)
patches, rewrites = VARIANTS.fetch(name)
lock = File.open(File.join(__dir__, "runs/.lock"), File::CREAT | File::RDWR)
abort "another driver is running" unless lock.flock(File::LOCK_EX | File::LOCK_NB)

progs = Zlib::GzipReader.open(File.join(EXP, "results-head/typeprof.jsonl.gz")) { |z| z.each_line.map { JSON.parse(_1) } }
progs = progs.select { _1["errors"]&.any? }.map { _1["path"] }
scratch = File.join(__dir__, "runs/src-#{name}")
out = File.open(File.join(__dir__, "runs/#{name}.jsonl"), "w")
reqs = patches.flat_map { ["-r", File.join(__dir__, "patches/#{_1}.rb")] }
progs.each_with_index do |path, i|
  src = File.read(File.join(EXP, path))
  stats = {}
  src, stats = Rewrite.apply(src, rewrites) unless rewrites.empty?
  file = File.join(scratch, path)
  FileUtils.mkdir_p(File.dirname(file))
  File.write(file, src)
  t = Time.now
  o, e, st = Open3.capture3("timeout", "120", RbConfig.ruby, *reqs, TYPEPROF, "--show-errors", file, rlimit_as: 3 * 1024**3)
  rec = { path:, sec: (Time.now - t).round(2), rewrites: stats }
  if st.success?
    rec[:errors] = o.lines.grep(/^# \(\d+,\d+\)-/).map { _1.delete_prefix("# ").chomp }
  else
    rec[:failed] = "exit #{st.exitstatus}: #{e.lines.last(2).join.strip[0, 200]}"
  end
  out.puts JSON.generate(rec); out.flush
  $stderr.puts "#{name} #{i + 1}/#{progs.size} #{path} #{rec[:sec]}s #{rec[:failed]}"
end
out.puts JSON.generate(done: name); out.close
