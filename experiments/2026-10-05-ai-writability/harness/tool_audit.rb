# frozen_string_literal: true

# Which shell commands did the reading agents run? ruby tool_audit.rb TRANSCRIPT_DIR MAP.tsv
# The reading tasks forbid running or evaluating anything. Prints, per agent, each Bash command that can
# compute (an interpreter, printf with a field width, awk, bc, expr, $((...)), seq), with the task directories it names.
# A task named by such a command is "assisted"; grade it separately, never silently.
require "json"

# a command word: at the start, or after a separator or space, and followed by a space (not "p5-ruby-predict/")
COMPUTE = %r{(?:\A|[\s;&|(])(python3?|ruby|perl|node|awk|gawk|bc|expr|seq|printf)(?=\s)|bin/sake|\$\(\(}
# printf with a field width (%-12s, %5d, %.2f) lays out columns: it computes padding. printf '%s\n' only writes lines.
LAYOUT = /%-?\d*\.?\d+[sdf]/
dir, map = ARGV
File.readlines(map).each do |line|
  name, id = line.chomp.split("\t")
  path = File.join(dir, "#{id}.output")
  abort "missing transcript #{path}" unless File.exist?(path)
  File.foreach(path) do |l|
    m = JSON.parse(l) rescue next
    next unless m["type"] == "assistant"
    (m.dig("message", "content") || []).each do |c|
      next unless c["type"] == "tool_use" && c["name"] == "Bash"
      cmd = c.dig("input", "command").to_s
      next unless cmd.match?(COMPUTE)
      tools = cmd.scan(COMPUTE).flatten.compact.uniq
      tools << "$((" if cmd.include?("$((")
      tools << "bin/sake" if cmd.include?("bin/sake")
      tools.delete("printf") unless cmd.match?(LAYOUT)
      next if tools.empty?
      tasks = cmd.scan(/\b([pf]\d\d)[-*]/).flatten.uniq # task numbers (a glob like p08* names one too)
      puts JSON.generate(agent: name, tasks:, tools:, command: cmd[0, 300])
    end
  end
end
