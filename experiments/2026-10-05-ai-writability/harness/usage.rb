# frozen_string_literal: true

# Token usage per solver agent, from Claude Code's subagent transcripts (JSONL):
#   ruby usage.rb TRANSCRIPT_DIR MAP.tsv   (MAP: run-name <TAB> agent id; transcript = DIR/<id>.output)
# Columns: calls (API calls), out (output tokens: thinking + text + tool input such as written code),
# final_ctx (last call's input + output = Claude Code's "subagent_tokens"), input_processed (sum of every
# call's input, mostly cache reads), wall (first to last record, seconds).
require "json"
require "time"

dir, map = ARGV
puts %w[run calls out final_ctx input_processed wall_s].join("\t")
File.readlines(map).each do |line|
  name, id = line.chomp.split("\t")
  path = File.join(dir, "#{id}.output")
  abort "missing transcript #{path}" unless File.exist?(path)
  seen = {}
  calls = out = sum_in = final = 0
  times = []
  File.foreach(path) do |l|
    m = JSON.parse(l) rescue next
    times << Time.parse(m["timestamp"]) if m["timestamp"]
    msg = m["message"]
    next unless m["type"] == "assistant" && msg && (u = msg["usage"])
    ctx = u["input_tokens"].to_i + u["cache_read_input_tokens"].to_i + u["cache_creation_input_tokens"].to_i
    unless seen.key?(msg["id"]) # a message is logged once per content block, with growing output counts
      calls += 1
      sum_in += ctx
    end
    o = u["output_tokens"].to_i
    prev = seen[msg["id"]] || 0
    out += o - prev if o > prev
    seen[msg["id"]] = [prev, o].max
    final = ctx + o
  end
  abort "no usage in #{path}" if calls.zero?
  puts [name, calls, out, final, sum_in, (times.max - times.min).round].join("\t")
end
