# frozen_string_literal: true

# P11: what a solver did, from its Claude Code transcript (JSONL).
#   ruby harness/actions_p11.rb TRANSCRIPT_DIR MAP.tsv     (MAP: run <TAB> agent id; transcript = DIR/<id>.output)
# Columns (one row per run):
#   out          output tokens (thinking + text + tool input), as harness/usage.rb counts them
#   input_proc   sum of every call's input tokens (mostly cache reads)
#   final_ctx    last call's input + output
#   reads        reading actions: Read/Grep/Glob calls and Bash commands made only of reading tools
#                (cat, sed -n, head, tail, grep, rg, find, wc, awk, ls, xargs, for/do/done loops of these)
#   read_lines   lines those actions returned, split into code_lines (the engine, SPEC.md, CHANGE.md and
#                anything else) and doc_lines (the language's documents: /home/ko1/app/sake/docs, the steep and
#                rbs gems); a Bash command that both reads and edits (python, ruby -e, sed -i) is not a read
#   edits        Edit/Write/MultiEdit calls on files under code/, and Bash commands that write there
#                (python, ruby -e, sed -i, cat > or tee into code/)
#   pre_edit_*   the same before the first edit (understanding before acting)
#   tests        Bash commands running run_tests.rb without --check-only; checks: check runs (check_sql.rb or --check-only)
#   rejected     checks or test runs whose output says the check failed
#   wall_s       first to last record
require "json"
require "time"

dir, map = ARGV
abort "usage: actions_p11.rb TRANSCRIPT_DIR MAP.tsv" unless dir && map
COLS = %w[run out input_proc final_ctx reads read_lines code_lines doc_lines edits
          pre_edit_reads pre_edit_code_lines pre_edit_doc_lines pre_edit_out tests checks rejected wall_s].freeze
puts COLS.join("\t")
READ_WORDS = /\A(cat|sed\s+-n|head|tail|grep|rg|find|wc|awk|ls|nl|echo|printf|cd|xargs|cut|sort|uniq|for\s+\w+\s+in\b.*|do|done|do\s+(cat|sed\s+-n|head|tail|grep|echo|printf|nl|wc)\b.*)(\s|\z)/
# a Bash command is a read when every piece (split at ; && || | and newlines, quotes blanked) starts with a reading word;
# `for f in a b; do cat $f; done` loops count (they were missed before 2026-10-08 22:00 JST)
def read_command?(cmd) = cmd.gsub(/"(?:\\.|[^"\\])*"|'[^']*'/, "Q").split(/\s*(?:&&|\|\||;|\||\n)\s*/).reject(&:empty?).all? { _1.strip.match?(READ_WORDS) }
WRITE_HINT = /\bsed\s+-i|\bpython3?\b|\bruby\s+-e|>\s*\S*code\/|\btee\b|\bperl\s+-[pi]/
DOC_RE = %r{/home/ko1/app/sake/docs|gems/(steep|rbs)-|gem contents|/docs/(tutorial|spec|builtins)}

File.readlines(map).each do |line|
  run, id = line.chomp.split("\t")
  path = File.join(dir, "#{id}.output")
  abort "missing transcript #{path}" unless File.exist?(path)
  s = Hash.new(0)
  seen = {}
  pending = {}
  times = []
  edited = false
  final = 0
  File.foreach(path) do |l|
    m = JSON.parse(l) rescue next
    times << Time.parse(m["timestamp"]) if m["timestamp"]
    msg = m["message"] or next
    if m["type"] == "assistant" && (u = msg["usage"])
      ctx = u["input_tokens"].to_i + u["cache_read_input_tokens"].to_i + u["cache_creation_input_tokens"].to_i
      s["input_proc"] += ctx unless seen.key?(msg["id"])
      o = u["output_tokens"].to_i
      prev = seen[msg["id"]] || 0
      if o > prev
        s["out"] += o - prev
        s["pre_edit_out"] += o - prev unless edited
      end
      seen[msg["id"]] = [prev, o].max
      final = ctx + o
    end
    content = msg["content"]
    next unless content.is_a?(Array)
    content.each do |c|
      if c["type"] == "tool_use"
        inp = c["input"] || {}
        case c["name"]
        when "Read", "Grep", "Glob"
          target = (inp["file_path"] || inp["path"] || inp["pattern"]).to_s
          pending[c["id"]] = [:read, target.match?(DOC_RE) ? "doc" : "code", edited]
          s["reads"] += 1
          s["pre_edit_reads"] += 1 unless edited
        when "Edit", "Write", "MultiEdit", "NotebookEdit"
          if inp["file_path"].to_s.include?("/code/")
            s["edits"] += 1
            edited = true
          end
        when "Bash"
          cmd = inp["command"].to_s
          if cmd.include?("check_sql.rb") || (cmd.include?("run_tests.rb") && cmd.include?("--check-only"))
            s["checks"] += 1
            pending[c["id"]] = [:check]
          elsif cmd.match?(/\bruby\s+(-\S+\s+)*\S*run_tests\.rb\b/)
            s["tests"] += 1
            pending[c["id"]] = [:test]
          elsif cmd.match?(WRITE_HINT) && cmd.include?("code")
            s["edits"] += 1
            edited = true
          elsif read_command?(cmd)
            pending[c["id"]] = [:read, cmd.match?(DOC_RE) ? "doc" : "code", edited]
            s["reads"] += 1
            s["pre_edit_reads"] += 1 unless edited
          end
        end
      elsif c["type"] == "tool_result" && (pv = pending.delete(c["tool_use_id"]))
        kind, where, after = pv
        text = c["content"].is_a?(Array) ? c["content"].map { _1["text"].to_s }.join : c["content"].to_s
        if kind == :read
          n = text.lines.size
          s["read_lines"] += n
          s["#{where}_lines"] += n
          s["pre_edit_#{where}_lines"] += n unless after
        elsif (text.include?("CHECK FAILED") || text.match?(/== check \d+ of \d+: FAILED/))
          s["rejected"] += 1
        end
      end
    end
  end
  abort "no usage in #{path}" if s["out"].zero?
  s["final_ctx"] = final
  s["wall_s"] = (times.max - times.min).round
  puts ([run] + COLS.drop(1).map { s[_1] }).join("\t")
end
