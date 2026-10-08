# frozen_string_literal: true

# P10: after the agent of a run's current stage finishes, grades that stage (grade_p10.rb) and, below
# stage 6, prepares the next one (prep_p10.rb), printing a one-line grade and the next prompt's path.
#   ruby harness/advance_p10.rb RUN
require_relative "common"

run = ARGV[0] or abort "usage: advance_p10.rb RUN"
meta = JSON.parse(File.read(File.join(AW::EXP, "runs", run, "meta.json")))
stage = meta["stage"]
out, st = Open3.capture2("ruby", File.join(__dir__, "grade_p10.rb"), run, stage.to_s)
abort "grade failed:\n#{out}" unless st.success?
g = JSON.parse(out)
puts "#{run} s#{stage}: public #{g["public_pass"]}/#{g["public_total"]} hidden #{g["hidden_pass"]}/#{g["hidden_total"]} lines #{g["lines"]} #{g["note"]}"
exit if stage == 6
system("ruby", File.join(__dir__, "prep_p10.rb"), run, meta["lang"], (stage + 1).to_s, exception: true)
