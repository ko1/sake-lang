# frozen_string_literal: true

# Controls for the tasks: ruby validate.rb TASK_DIR...
#   positive: ref.sake (at --strict=2) and ref.rb pass every public and hidden case;
#   negative: mutants of the references (one operator changed) must fail some hidden case.
# Prints one JSON line per task; exit 1 when a reference fails or no mutant is killed.
require_relative "common"

bad = false
ARGV.each do |task|
  rec = { task: File.basename(task) }
  %w[sake rb].each do |ext|
    ref = File.join(task, "ref.#{ext}")
    strict = ext == "sake" ? 2 : 0
    pub = AW.test(ref, task, "public", strict)
    hid = AW.test(ref, task, "hidden", strict)
    rec["#{ext}_ref_ok"] = (pub + hid).all? { _1[:ok] }
    rec["#{ext}_ref_fail"] = (pub + hid).reject { _1[:ok] }.map { |r| [r[:name], r[:status], r[:err][0, 200]] }
    ms = AW.mutants(File.read(ref)).sample(12, random: Random.new(1))
    tmp = File.join(task, ".mutant.#{ext}")
    killed = ms.count do |m|
      File.write(tmp, m)
      AW.test(tmp, task, "hidden", 0).any? { !_1[:ok] }
    end
    File.delete(tmp) if File.exist?(tmp)
    rec["#{ext}_mutants"] = ms.size
    rec["#{ext}_killed"] = killed
    bad ||= !rec["#{ext}_ref_ok"] || (ms.size > 0 && killed.zero?)
  end
  puts JSON.generate(rec)
end
exit(bad ? 1 : 0)
