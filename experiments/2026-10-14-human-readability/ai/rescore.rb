# Re-reads every answer from the saved text with run.rb's answer_line (the first scoring took the last line, which a trailing note could fill).
require "json"
src = File.read(File.join(__dir__, "run.rb"))
eval(src[/^def answer_line.*?^end\n/m])
items = JSON.parse(File.read(File.join(__dir__, "../items.json"))).to_h { [_1["id"], _1] }
ARGV.each do |f|
  changed = 0; missing = 0
  rows = File.readlines(f).map do |l|
    r = JSON.parse(l); it = items[r["id"]]
    a = answer_line(r["text"], r["kind"])
    if a.nil? then missing += 1; r["ans"] = nil; r["ok"] = false; r["unparsed"] = true
    elsif r["kind"] == "review" then ok = (a == "BUG") == it["bug"]; changed += 1 if ok != r["ok"]; r["ans"] = a; r["ok"] = ok
    else
      rng = Random.new(r["rep"] * 100 + r["id"].sum); order = (0...4).to_a.shuffle(random: rng)
      ans = order["ABCD".index(a)]; changed += 1 if (ans == 0) != r["ok"]; r["ans"] = ans; r["ok"] = ans == 0
    end
    r
  end
  File.write(f, rows.map { JSON.generate(_1) + "\n" }.join)
  puts "#{f}: #{rows.size} answers, #{changed} rescored, #{missing} without an answer line"
end
