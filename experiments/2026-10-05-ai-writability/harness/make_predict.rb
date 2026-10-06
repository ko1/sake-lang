# frozen_string_literal: true

# Output-prediction tasks (P5): ruby make_predict.rb   -> reading/pNN-<slug>/{base.txt, cases/1.in 1.out 2.in 2.out}
# Per base task, the two hidden cases with the largest input among those with 4-20 input lines and 4-15
# output lines (enough to exercise the program, short enough to trace by hand). The reader gets the
# reference program and the inputs, never spec.md, so the answer has to come from reading the code.
require "fileutils"

exp = File.expand_path("..", __dir__)
Dir[File.join(exp, "tasks", "b*")].sort.each do |task|
  cases = Dir[File.join(task, "hidden", "*.in")].sort.map do |i|
    o = i.sub(/\.in\z/, ".out")
    [i, o, File.readlines(i).size, File.readlines(o).size]
  end
  pick = cases.select { |_, _, ni, no| ni.between?(4, 20) && no.between?(4, 15) }.max_by(2) { |c| [c[2], c[0]] }
  abort "#{task}: only #{pick.size} cases fit" if pick.size < 2
  dir = File.join(exp, "reading", File.basename(task).sub(/\Ab/, "p"))
  abort "#{dir} exists" if File.exist?(dir)
  FileUtils.mkdir_p(File.join(dir, "cases"))
  File.write(File.join(dir, "base.txt"), "#{File.basename(task)}\n")
  pick.sort_by(&:first).each_with_index do |(i, o, *), k|
    FileUtils.cp(i, File.join(dir, "cases", "#{k + 1}.in"))
    FileUtils.cp(o, File.join(dir, "cases", "#{k + 1}.out"))
  end
  puts "#{File.basename(dir)}: #{pick.sort_by(&:first).map { |c| "#{File.basename(c[0])} (#{c[2]} in / #{c[3]} out)" }.join(", ")}"
end
