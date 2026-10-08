# frozen_string_literal: true

# P10: closes stage STAGE of run RUN: copies runs/RUN/code to runs/RUN/stage-STAGE/code, then runs the
# public and the hidden tests of stages 1..STAGE on that copy and appends one line to
# runs/grade-p10.jsonl.
#   ruby harness/grade_p10.rb RUN STAGE [--regrade]
# Per stage it records passed/total for public and hidden tests. A count that cannot be read from the
# runner's output fails the script instead of being recorded as 0. --regrade grades an existing copy.
require "fileutils"
require_relative "common"

run, stage_s, flag = ARGV
abort "usage: grade_p10.rb RUN STAGE [--regrade]" unless run && stage_s
stage = Integer(stage_s)
work = File.join(AW::EXP, "runs", run)
meta = JSON.parse(File.read(File.join(work, "meta.json")))
snap = File.join(work, "stage-#{stage}")
if flag == "--regrade"
  abort "#{snap} missing" unless File.directory?(snap)
else
  abort "#{snap} exists (use --regrade)" if File.exist?(snap)
  abort "meta.json says stage #{meta["stage"]}, not #{stage}" unless meta["stage"] == stage
  FileUtils.mkdir_p(snap)
  FileUtils.cp_r(File.join(work, "code"), File.join(snap, "code"))
end
# runs made before the other languages have "ext" only
entry = meta["entry"] || "main.#{meta["ext"]}"
exts = meta["exts"] || [meta["ext"]]
main = File.join(snap, "code", entry)
abort "#{main} missing" unless File.exist?(main)

files = exts.flat_map { |e| Dir.glob(File.join(snap, "code", "**", "*.#{e}")) }
line_count = ->(f) { File.readlines(f).count { |l| !l.strip.empty? } }
lines = files.sum(&line_count)
lines_by_ext = exts.to_h { |e| [e, files.select { _1.end_with?(".#{e}") }.sum(&line_count)] }

runner = File.join(AW::EXP, "large", "sql", "run_tests.rb")
flags = meta["flag"].to_s.split
def run_suite(runner, main, flags, stage, tests_dir)
  env = { "SQL_TESTS" => tests_dir }
  t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  out, err, _st = Open3.capture3(env, "ruby", runner, main, *flags, "--stage", stage.to_s)
  secs = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  text = out + err
  per = Hash.new { |h, k| h[k] = { "total" => 0, "failed" => 0 } }
  (1..stage).each { |n| per[n.to_s]["total"] = Dir.glob(File.join(tests_dir, n.to_s, "*.sql")).length }
  if text.start_with?("CHECK FAILED")
    per.each_value { |v| v["failed"] = v["total"] }
    return [per, secs, "check failed"]
  end
  m = text.match(/^(\d+) passed, (\d+) failed \((\d+) tests/)
  abort "no summary line from run_tests.rb:\n#{text.lines.last(10).join}" unless m
  text.scan(%r{^FAIL (\d+)/}) { |(n)| per[n]["failed"] += 1 }
  text.scan(%r{^MISSING (\d+)/}) { |(n)| per[n]["failed"] += 1 }
  total = per.values.sum { _1["total"] }
  abort "runner ran #{m[3]} tests, expected #{total}" unless Integer(m[3]) == total
  abort "runner failed #{m[2]}, counted #{per.values.sum { _1["failed"] }}" unless Integer(m[2]) == per.values.sum { _1["failed"] }
  [per, secs, nil]
end

pub, pub_secs, pub_note = run_suite(runner, main, flags, stage, File.join(AW::EXP, "large", "sql", "tests"))
hid, hid_secs, hid_note = run_suite(runner, main, flags, stage, File.join(AW::EXP, "tasks", "sql-hidden"))
fmt = ->(per) { per.sort_by { |k, _| k.to_i }.to_h { |k, v| [k, "#{v["total"] - v["failed"]}/#{v["total"]}"] } }
row = { run:, lang: meta["lang"], stage:, files: files.length, lines:, lines_by_ext:,
        public: fmt.(pub), hidden: fmt.(hid),
        public_pass: pub.values.sum { _1["total"] - _1["failed"] }, public_total: pub.values.sum { _1["total"] },
        hidden_pass: hid.values.sum { _1["total"] - _1["failed"] }, hidden_total: hid.values.sum { _1["total"] },
        suite_secs: { public: pub_secs.round(1), hidden: hid_secs.round(1) }, note: [pub_note, hid_note].compact.uniq.join }
File.open(File.join(AW::EXP, "runs", "grade-p10.jsonl"), "a") { _1.puts(JSON.generate(row)) }
puts JSON.pretty_generate(row)
