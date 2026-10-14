# Asks a model the page's 12 questions through `claude -p` (no tools, a short system prompt) and writes one JSON line per answer.
# usage: ruby run.rb MODEL N OUT.jsonl   (conditions: ruby, sake without the primer, sake with the page's primer)
require "json"; require "open3"
ORIG_DIR = Dir.pwd
Dir.chdir(File.expand_path("..", __dir__))
SETUP = /\A(p |users = |text = |values = |defaults = |prefs = |results = |ns = |scores = |#)/
def sections(path)
  src = File.read(path).split(/^# ([RG]\d)\n/); src.shift
  src.each_slice(2).to_h { |id, body| [id, body.lines.reject { _1 =~ SETUP }.join.strip] }
end
CODE = { "ruby" => sections("check/all.rb"), "sake" => sections("check/all.sake") }
ITEMS = JSON.parse(File.read("items.json"))
PRIMER = <<~P
  Sake は Ruby によく似た言語で、値にメソッドを呼ぶ代わりに、型の名前を付けた関数として呼びます。
  # Ruby                          # Sake
  xs.map { |x| x * 2 }            Array.map(xs) { |x| x * 2 }
  u.name                          User.name(u)
  xs.select { }.map { }           Array.select(xs) { }.Array.map { }
P
NOTE = "型の誤り（存在しないメソッド、型の取り違え）は入っていません。検査を通ったコードだと思って読んでください。"
# The answer is the last line holding only the answer (a closing note may follow it, e.g. a notice about MCP servers).
def answer_line(text, kind)
  pat = kind == "review" ? /\A[*`(\s]*(OK|BUG)[*`)\s。.]*\z/ : /\A[*`(\s]*([A-D])[*`)\s。.]*\z/
  text.lines.map(&:strip).reverse.find { _1 =~ pat }&.then { _1[pat, 1] }
end
def tail(c, what) = c.end_with?("/glance") ? "説明は書かず、#{what} だけを答えてください。" : "最後の行に #{what} だけを書いてください。"
model, n, out = ARGV[0], Integer(ARGV[1]), File.expand_path(ARGV[2], ORIG_DIR)
conds = %w[ruby sake sake+primer]
conds = conds.map { "#{_1}/glance" } if ENV["GLANCE"]  # no reasoning: the answer only, like a glance
jobs = []
n.times { |rep| ITEMS.each { |it| conds.each { |c| jobs << [rep, it, c] } } }
jobs.select! { ENV["ONLY"].nil? || ENV["ONLY"].split(",").include?(_1[1]["id"]) }
jobs.shuffle!(random: Random.new(1))
q = Queue.new; jobs.each { q << _1 }; 8.times { q << nil }
mu = Mutex.new; f = File.open(out, "a")
8.times.map {
  Thread.new {
    while (job = q.pop)
      rep, it, c = job
      lang = c.start_with?("sake") ? "Sake" : "Ruby"
      code = CODE[lang.downcase][it["id"]]
      pre = c.start_with?("sake+primer") ? PRIMER + "\n" : ""
      if it["kind"] == "review"
        ask = "#{pre}次の #{lang} のコードは仕様どおりですか。#{NOTE}\n\n仕様: #{it["spec"]}\n\n```\n#{code}\n```\n\n#{tail(c, "OK か BUG")}"
      else
        rng = Random.new(rep * 100 + it["id"].sum)
        order = (0...4).to_a.shuffle(random: rng)
        ask = "#{pre}次の #{lang} のコードは何をしますか。\n\n```\n#{code}\n```\n\n" +
              order.each_with_index.map { |ci, k| "#{"ABCD"[k]}. #{it["choices"][ci]}" }.join("\n") +
              "\n\n#{tail(c, "A〜D の記号")}"
      end
      think = c.end_with?("/glance") ? ["--settings", %q({"alwaysThinkingEnabled":false})] : []
      o, e, st = Open3.capture3({ "MAX_THINKING_TOKENS" => (c.end_with?("/glance") ? "0" : nil) }, "claude", "-p", *think, "--model", model, "--output-format", "json", "--tools", "", "--strict-mcp-config",
                                "--system-prompt", "あなたはコードレビュアーです。質問に簡潔に答えてください。", stdin_data: ask)
      r = (JSON.parse(o) rescue nil)
      raise "claude failed: #{e} #{o[0, 300]}" unless st.success? && r && r["result"]
      text = r["result"]; last = answer_line(text, it["kind"]).to_s
      if it["kind"] == "review"
        ans = last[/BUG|OK/] or raise "no answer: #{text[-200..]}"
        ok = (ans == "BUG") == it["bug"]
      else
        k = last[/[A-D]/] or raise "no answer: #{text[-200..]}"
        ans = order["ABCD".index(k)]; ok = ans == 0
      end
      rec = { model:, rep:, id: it["id"], kind: it["kind"], cond: c, ans:, ok:,
              out_tokens: r.dig("usage", "output_tokens"), think_tokens: r.dig("usage", "output_tokens_details", "thinking_tokens"), ms: r["duration_api_ms"], text: }
      mu.synchronize { f.puts JSON.generate(rec); f.flush }
    end
  }
}.each(&:join)
