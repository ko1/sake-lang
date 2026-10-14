# Builds glance.html from template.html, taking each item's code from check/all.rb and check/all.sake
# (the programs that were run and compared), without the lines that only set up data or print.
require "json"
SETUP = /\A(p |users = |text = |values = |defaults = |prefs = |results = |ns = |scores = |#)/
def sections(path)
  src = File.read(path).split(/^# ([RG]\d)\n/)
  src.shift
  src.each_slice(2).to_h { |id, body| [id, body.lines.reject { _1 =~ SETUP }.join.strip] }
end
rb = sections("check/all.rb")
sk = sections("check/all.sake")
meta = JSON.parse(File.read("items.json"))
items = meta.map { |m| m.merge("ruby" => rb.fetch(m["id"]), "sake" => sk.fetch(m["id"])) }
html = File.read("template.html").sub("/*ITEMS*/[]", JSON.generate(items).gsub("</", "<\\/"))
File.write("glance.html", html)
items.each { |i| puts "== #{i["id"]}", i["ruby"], "--", i["sake"] }
