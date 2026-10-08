# frozen_string_literal: true

# P11 summary: joins runs/grade-p11.jsonl (last row per run) with the solvers' transcripts (actions_p11.rb) and
# prints, per mode: one row per run, then per language x change means, then the wide-minus-local contrast.
#   ruby harness/summarize_p11.rb TRANSCRIPT_DIR > runs/summary-p11.txt
# Wide changes: c1 c2 c3; local: c4 c5 c6. Mode h (hard: no list of places) has only wide changes; its contrast
# uses mode n's local changes. A run without a grade or a transcript stops the script.
require "json"
require "open3"
require "tmpdir"

EXP = File.expand_path("..", __dir__)
tdir = ARGV[0] or abort "usage: summarize_p11.rb TRANSCRIPT_DIR"
WIDE = %w[c1 c2 c3].freeze
LANGS = %w[ruby java haskell scheme steep sake].freeze

grades = {}
File.foreach(File.join(EXP, "runs", "grade-p11.jsonl")) { |l| r = JSON.parse(l); grades[r["run"]] = r }
agents = File.readlines(File.join(EXP, "runs", "agents-p11.tsv")).drop(1).map { _1.chomp.split("\t") }
agents.select! { |run, _| grades.key?(run) }
map = File.join(Dir.tmpdir, "p11-map-#{$$}.tsv")
File.write(map, agents.map { _1.join("\t") }.join("\n") + "\n")
out, st = Open3.capture2("ruby", File.join(__dir__, "actions_p11.rb"), tdir, map)
abort "actions_p11.rb failed" unless st.success?
File.delete(map)
rows = out.lines.drop(1).map do |l|
  f = l.chomp.split("\t")
  a = %w[run out input_proc final_ctx reads read_lines code_lines doc_lines edits pre_edit_reads pre_edit_code_lines pre_edit_doc_lines pre_edit_out tests checks rejected wall_s]
      .zip(f).to_h
  g = grades.fetch(a["run"])
  checks_log = File.join(EXP, "runs", a["run"], "attempts.jsonl")
  attempts = File.exist?(checks_log) ? File.readlines(checks_log).map { JSON.parse(_1) } : []
  a.transform_values! { _1 =~ /\A\d+\z/ ? Integer(_1) : _1 }
  a.merge("mode" => g["mode"], "lang" => g["lang"], "change" => g["change"][/\Ac\d/],
          "hid" => g["hidden7_pass"].fdiv(g["hidden7_total"]), "hid_s" => "#{g["hidden7_pass"]}/#{g["hidden7_total"]}",
          "reg" => g["regressions_hidden"].size + g["regressions_public"].size,
          "diff" => g["diff_added"] + g["diff_removed"], "files" => g["files_changed"],
          "n_checks" => attempts.size, "n_check_fail" => attempts.count { !_1["check_ok"] },
          "check_secs" => attempts.sum { _1["secs"].to_f })
end

mean = ->(xs) { xs.empty? ? nil : xs.sum.fdiv(xs.size) }
fmt = ->(x, d = 1) { x.nil? ? "-" : format("%.#{d}f", x) }

%w[n h t].each do |mode|
  rs = rows.select { _1["mode"] == mode }
  # hard mode has only the wide changes; its local side is mode n's local changes (same rules: no run, check only)
  locals = mode == "h" ? rows.select { _1["mode"] == "n" && !WIDE.include?(_1["change"]) } : rs.select { !WIDE.include?(_1["change"]) }
  next if rs.empty?
  puts "== mode #{mode} (#{rs.size} runs)"
  puts %w[run hidden reg diff files out_k in_M pre_reads pre_code pre_doc reads code_lines doc_lines checks fail wall_min].join("\t")
  rs.sort_by { [_1["change"], LANGS.index(_1["lang"]), _1["run"]] }.each do |r|
    puts [r["run"], r["hid_s"], r["reg"], r["diff"], r["files"], fmt.(r["out"] / 1000.0), fmt.(r["input_proc"] / 1e6, 2),
          r["pre_edit_reads"], r["pre_edit_code_lines"], r["pre_edit_doc_lines"], r["reads"], r["code_lines"], r["doc_lines"],
          mode != "t" ? r["n_checks"] : r["checks"], mode != "t" ? r["n_check_fail"] : r["rejected"], fmt.(r["wall_s"] / 60.0)].join("\t")
  end
  puts
  puts "-- per language: wide (c1-c3) | local (c4-c6) | wide/local (tokens, reads) or wide-local (pass rate)"
  puts %w[lang n_w n_l pass_w pass_l d_pass reg_w reg_l out_w out_l r_out pre_code_w pre_code_l r_pre in_w in_l r_in].join("\t")
  LANGS.each do |lang|
    w = rs.select { _1["lang"] == lang && WIDE.include?(_1["change"]) }
    l = locals.select { _1["lang"] == lang }
    next if w.empty? && l.empty?
    m = ->(set, k) { mean.(set.map { _1[k].to_f }) }
    ow, ol = m.(w, "out"), m.(l, "out")
    pw, pl = m.(w, "pre_edit_code_lines"), m.(l, "pre_edit_code_lines")
    iw, il = m.(w, "input_proc"), m.(l, "input_proc")
    ratio = ->(a, b) { a && b && b.positive? ? a / b : nil }
    puts [lang, w.size, l.size, fmt.(m.(w, "hid"), 3), fmt.(m.(l, "hid"), 3), fmt.(m.(w, "hid") && m.(l, "hid") && m.(w, "hid") - m.(l, "hid"), 3),
          fmt.(m.(w, "reg")), fmt.(m.(l, "reg")), fmt.(ow && ow / 1000), fmt.(ol && ol / 1000), fmt.(ratio.(ow, ol), 2),
          fmt.(pw, 0), fmt.(pl, 0), fmt.(ratio.(pw, pl), 2), fmt.(iw && iw / 1e6, 2), fmt.(il && il / 1e6, 2), fmt.(ratio.(iw, il), 2)].join("\t")
  end
  puts
end
