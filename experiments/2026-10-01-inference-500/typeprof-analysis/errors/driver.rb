# Counterfactual runs of TypeProf over the programs that had errors in results-head.
# usage: ruby driver.rb VARIANT    (writes runs/VARIANT.jsonl)
# A variant is a set of TypeProf monkey patches (patches/*.rb) plus source rewrites (rewrite.rb),
# applied to a scratch copy of each program; the corpus is never modified.
# One process loads TypeProf, the patches and the core RBS once, then forks one child per program
# (120 s CPU-time alarm, 3 GB address space), so only one analysis runs at a time. Each child does
# what `typeprof --show-errors FILE` does: update_file on a Service with only the core RBS, then diagnostics.
require "json"
require "zlib"
require "fileutils"
require "timeout"
require_relative "rewrite"

EXP = File.expand_path("../..", __dir__)
TPLOCK = File.join(__dir__, "runs/.tplock") # every typeprof process (driver and ad-hoc probes) takes this lock
VARIANTS = {
  "V0" => [[], []],                                                     # harness check: must equal results-head
  "V1" => [%w[interface], []],
  "V2" => [%w[interface numeric_catchall], []],
  "V3" => [%w[interface numeric_catchall masgn], []],
  "V4" => [%w[interface numeric_catchall masgn sigvertex], []],
  "V5" => [%w[interface numeric_catchall masgn sigvertex], %i[modfunc]],
  "V6" => [%w[interface numeric_catchall masgn sigvertex], %i[modfunc shadow]],
  "V7" => [%w[interface numeric_catchall masgn sigvertex], %i[modfunc shadow nilq]],
  "V8" => [%w[interface numeric_catchall masgn sigvertex], %i[modfunc shadow nilq acond]],
  "V9" => [%w[interface numeric_catchall masgn sigvertex rbs_nonnil], %i[modfunc shadow nilq acond]],
  "V10" => [%w[interface numeric_catchall masgn sigvertex rbs_nonnil nil_literal], %i[modfunc shadow nilq acond]],
  "V11" => [%w[interface numeric_catchall masgn sigvertex rbs_nonnil nil_literal empty_arg], %i[modfunc shadow nilq acond]],
  # single-factor variants (each change alone, on top of nothing)
  "S-interface" => [%w[interface], []], "S-numeric_catchall" => [%w[numeric_catchall], []],
  "S-masgn" => [%w[masgn], []], "S-sigvertex" => [%w[sigvertex], []], "S-modfunc" => [[], %i[modfunc]],
  "S-shadow" => [[], %i[shadow]], "S-nilq" => [[], %i[nilq]], "S-acond" => [[], %i[acond]],
  "S-rbs_nonnil" => [%w[rbs_nonnil], []], "S-nil_literal" => [%w[nil_literal], []], "S-empty_arg" => [%w[empty_arg], []],
}
name = ARGV.fetch(0)
patches, rewrites = VARIANTS.fetch(name)
require "typeprof"
patches.each { require_relative "patches/#{_1}" }
CORE = TypeProf::Core::Service.new({ output_diagnostics: true }) # each forked child gets a pristine copy

progs = Zlib::GzipReader.open(File.join(EXP, "results-head/typeprof.jsonl.gz")) { |z| z.each_line.map { JSON.parse(_1) } }
progs = progs.select { _1["errors"]&.any? }.map { _1["path"] }
scratch = File.join(__dir__, "runs/src-#{name}")
out = File.open(File.join(__dir__, "runs/#{name}.jsonl"), "w")
lock = File.open(TPLOCK, File::CREAT | File::RDWR)
# attribute.rb stops at a program's first failed variant, so later variants skip it
prev = VARIANTS.keys[VARIANTS.keys.index(name) - 1]
prev_failed = name == "V0" || !name.start_with?("V") ? {} : File.readlines(File.join(__dir__, "runs/#{prev}.jsonl")).map { JSON.parse(_1) }.select { _1["failed"] }.to_h { [_1["path"], true] }
progs.each_with_index do |path, i|
  if prev_failed[path]
    out.puts JSON.generate(path:, sec: 0, failed: "skipped: failed in #{prev}"); out.flush
    next
  end
  src = File.read(File.join(EXP, path))
  stats = {}
  src, stats = Rewrite.apply(src, rewrites) unless rewrites.empty?
  file = File.join(scratch, path)
  FileUtils.mkdir_p(File.dirname(file))
  File.write(file, src)
  lock.flock(File::LOCK_EX)
  t = Time.now
  rd, wr = IO.pipe
  pid = fork do
    rd.close
    Process.setrlimit(:AS, 3 * 1024**3)
    Process.setrlimit(:CPU, 120)
    core = CORE
    core.update_file(file, File.read(file)) or raise "failed to analyze"
    errs = []
    core.diagnostics(file) { |d| errs << "#{d.code_range}:#{d.msg}" }
    wr.write JSON.generate(errs)
    exit!(0)
  end
  wr.close
  body = rd.read
  _, st = Process.wait2(pid)
  lock.flock(File::LOCK_UN)
  rec = { path:, sec: (Time.now - t).round(2), rewrites: stats }
  if st.success?
    rec[:errors] = JSON.parse(body)
  else
    rec[:failed] = st.inspect
  end
  out.puts JSON.generate(rec); out.flush
  $stderr.puts "#{name} #{i + 1}/#{progs.size} #{path} #{rec[:sec]}s #{rec[:failed]}"
end
out.puts JSON.generate(done: name); out.close
