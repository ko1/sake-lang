#!/usr/bin/env ruby
# frozen_string_literal: true

# Generates the Ruby-vs-Sake comparison page: for each library port, the test program written with Ruby's own
# library (test/sakelib/NAME.rb) next to the same program in Sake (test/sakelib/NAME.sake), and the port itself
# (sakelib/NAME.sake).
#   ruby tools/gen_compare.rb OUT.html             a full HTML document (the GitHub Pages site)
#   ruby tools/gen_compare.rb --fragment OUT.html  without <!doctype>/<head> (an Artifact page)
require "json"
require "erb"

ROOT = File.expand_path("..", __dir__)
fragment = ARGV.delete("--fragment")
out = ARGV.fetch(0) { abort "usage: gen_compare.rb [--fragment] OUT.html" }

# Lines that carry code: not blank and not only a comment.
def code_lines(text) = text.lines.count { |l| (s = l.strip) != "" && !s.start_with?("#") }

libs = Dir.glob("test/sakelib/*.sake", base: ROOT).sort.filter_map do |path|
  name = File.basename(path, ".sake")
  rb = File.join(ROOT, "test/sakelib/#{name}.rb")
  next unless File.exist?(rb)
  sake_test = File.read(File.join(ROOT, path))
  ruby_test = File.read(rb)
  port_path = File.join(ROOT, "sakelib/#{name}.sake")
  port = File.exist?(port_path) ? File.read(port_path) : nil
  {
    name:,
    ruby: ruby_test,
    sake: sake_test,
    port:,
    rl: code_lines(ruby_test),
    sl: code_lines(sake_test),
    pl: port && code_lines(port),
    notes: File.exist?(File.join(ROOT, "sakelib/notes/#{name}.md")),
  }
end

total_r = libs.sum { _1[:rl] }
total_s = libs.sum { _1[:sl] }
ratios = libs.map { _1[:sl].to_f / [_1[:rl], 1].max }.sort
median = ratios.empty? ? 0 : ratios[ratios.size / 2]
data = JSON.generate(libs).gsub("</", "<\\/")
stamp = Time.now.utc.strftime("%Y-%m-%d")

page = ERB.new(<<~'HTML', trim_mode: "-").result(binding)
  <title>Ruby and Sake, side by side</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=IBM+Plex+Mono:wght@400;500&family=IBM+Plex+Sans+JP:wght@400;500;700&display=swap">
  <style>
    /* Layout: a library list on the left, two code columns (Ruby | Sake) on the right; stacks below 900px. */
    :root {
      --bg: #f6f7f9; --panel: #ffffff; --fg: #1d2330; --muted: #5d6677; --line: #dde1e8;
      --ruby: #b3261e; --sake: #11706b; --accent: #2f4fa8; --code-bg: #fbfbfc; --sel: #e8edf8;
      --k: #8a3ffc; --s: #0b7a3b; --n: #a35200; --c: #7b8394; --t: #1d4ed8; --sym: #a11d6f;
      --font-ui: "IBM Plex Sans JP", "Hiragino Sans", "Noto Sans JP", system-ui, sans-serif;
      --font-code: "IBM Plex Mono", ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace;
    }
    @media (prefers-color-scheme: dark) {
      :root:not([data-theme="light"]) {
        --bg: #12151b; --panel: #191d25; --fg: #e6e9ef; --muted: #98a1b2; --line: #2a303b;
        --ruby: #ff8a80; --sake: #5fd3c9; --accent: #8fa8ff; --code-bg: #151920; --sel: #24304a;
        --k: #c4a1ff; --s: #7fdc9a; --n: #ffb870; --c: #7d8799; --t: #93b4ff; --sym: #f39ac9;
        color-scheme: dark;
      }
    }
    :root[data-theme="dark"] {
      --bg: #12151b; --panel: #191d25; --fg: #e6e9ef; --muted: #98a1b2; --line: #2a303b;
      --ruby: #ff8a80; --sake: #5fd3c9; --accent: #8fa8ff; --code-bg: #151920; --sel: #24304a;
      --k: #c4a1ff; --s: #7fdc9a; --n: #ffb870; --c: #7d8799; --t: #93b4ff; --sym: #f39ac9;
      color-scheme: dark;
    }
    * { box-sizing: border-box; }
    body { margin: 0; background: var(--bg); color: var(--fg); font-family: var(--font-ui); font-size: 14px; }
    .wrap { padding-inline: 16px; padding-block: 20px 40px; max-width: 1500px; margin: 0 auto; display: grid; gap: 16px; }
    header h1 { font-size: 1.35rem; margin: 0 0 4px; text-wrap: balance; }
    header p { margin: 0; color: var(--muted); max-width: 70ch; line-height: 1.6; }
    .sum { display: flex; flex-wrap: wrap; gap: 8px 20px; margin-top: 10px; font-variant-numeric: tabular-nums; color: var(--muted); }
    .sum b { color: var(--fg); font-weight: 500; }
    .main { display: grid; grid-template-columns: 260px minmax(0, 1fr); gap: 16px; align-items: start; }
    @media (max-width: 900px) { .main { grid-template-columns: minmax(0, 1fr); } }
    nav { background: var(--panel); border: 1px solid var(--line); border-radius: 8px; display: grid; grid-template-rows: auto auto 1fr; max-height: calc(100vh - 40px); position: sticky; top: env(safe-area-inset-top, 0px); }
    @media (max-width: 900px) { nav { position: static; max-height: 40vh; } }
    nav input, nav select { margin: 10px 10px 0; padding: 6px 8px; border: 1px solid var(--line); border-radius: 6px; background: var(--bg); color: var(--fg); font: inherit; }
    nav select { margin-bottom: 8px; }
    nav ul { list-style: none; margin: 0; padding: 0 0 8px; overflow-y: auto; }
    nav li button { width: 100%; display: flex; justify-content: space-between; gap: 8px; padding: 5px 12px; border: 0; background: none; color: var(--fg); font: inherit; text-align: left; cursor: pointer; font-variant-numeric: tabular-nums; }
    nav li button:hover { background: var(--sel); }
    nav li button[aria-current="true"] { background: var(--sel); font-weight: 700; }
    nav li button:focus-visible, .tabs button:focus-visible { outline: 2px solid var(--accent); outline-offset: -2px; }
    nav .r { color: var(--muted); }
    section { min-width: 0; display: grid; gap: 10px; }
    .head { display: flex; flex-wrap: wrap; align-items: baseline; gap: 6px 16px; }
    .head h2 { margin: 0; font-size: 1.2rem; font-family: var(--font-code); font-weight: 500; }
    .chips { display: flex; flex-wrap: wrap; gap: 6px; font-variant-numeric: tabular-nums; }
    .chip { border: 1px solid var(--line); border-radius: 999px; padding: 1px 9px; color: var(--muted); background: var(--panel); }
    .chip b { font-weight: 500; color: var(--fg); }
    .head a { color: var(--accent); }
    .tabs { display: flex; gap: 4px; border-bottom: 1px solid var(--line); }
    .tabs button { border: 0; background: none; padding: 6px 12px; font: inherit; color: var(--muted); cursor: pointer; border-bottom: 2px solid transparent; }
    .tabs button[aria-selected="true"] { color: var(--fg); border-bottom-color: var(--accent); font-weight: 500; }
    .cols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 12px; }
    @media (max-width: 1100px) { .cols { grid-template-columns: minmax(0, 1fr); } }
    .col { min-width: 0; background: var(--panel); border: 1px solid var(--line); border-radius: 8px; overflow: hidden; }
    .col h3 { margin: 0; padding: 6px 12px; font-size: 0.8rem; letter-spacing: 0.06em; text-transform: uppercase; border-bottom: 1px solid var(--line); display: flex; justify-content: space-between; }
    .col.ruby h3 { color: var(--ruby); }
    .col.sake h3 { color: var(--sake); }
    .col h3 span { color: var(--muted); text-transform: none; letter-spacing: 0; font-weight: 400; }
    pre { margin: 0; padding: 8px 0; overflow-x: auto; background: var(--code-bg); font-family: var(--font-code); font-size: 12.5px; line-height: 1.55; counter-reset: ln; }
    pre code { display: block; }
    .ln { display: block; padding-right: 12px; white-space: pre; }
    .ln::before { counter-increment: ln; content: counter(ln); display: inline-block; width: 3.2em; padding-right: 0.9em; text-align: right; color: var(--c); user-select: none; }
    .hljs-keyword, .hljs-built_in { color: var(--k); }
    .hljs-string, .hljs-regexp { color: var(--s); }
    .hljs-number, .hljs-literal { color: var(--n); }
    .hljs-comment { color: var(--c); font-style: italic; }
    .hljs-title, .hljs-title.class_, .hljs-title.function_ { color: var(--t); }
    .hljs-symbol, .hljs-variable, .hljs-params { color: var(--sym); }
    .empty { padding: 16px; color: var(--muted); }
  </style>
  <div class="wrap">
    <header>
      <h1>Ruby and Sake, side by side</h1>
      <p>Each Sake library in <code>sakelib/</code> has a test program written twice: once with Ruby's own library and once in Sake on the port. The two print the same output (the test suite checks it). Read them in parallel to see what Sake asks you to write differently; the third tab is the port itself.</p>
      <div class="sum">
        <span><b><%= libs.size %></b> libraries</span>
        <span>test programs: Ruby <b><%= total_r %></b> lines, Sake <b><%= total_s %></b> lines (code lines, comments and blanks excluded)</span>
        <span>median Sake/Ruby <b><%= format("%.2f", median) %></b></span>
        <span>generated <%= stamp %></span>
      </div>
    </header>
    <div class="main">
      <nav aria-label="Libraries">
        <input id="filter" type="search" placeholder="Filter libraries" aria-label="Filter libraries">
        <select id="sort" aria-label="Sort">
          <option value="name">Sort by name</option>
          <option value="ratio">Sort by Sake/Ruby, largest first</option>
          <option value="size">Sort by Ruby lines, largest first</option>
        </select>
        <ul id="list"></ul>
      </nav>
      <section id="view" aria-live="polite"></section>
    </div>
  </div>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/highlight.js/11.9.0/highlight.min.js"></script>
  <script>
  const LIBS = <%= data %>;
  const REPO = "https://github.com/ko1/sake-lang/blob/main/";
  let current = null, tab = "tests";
  const $ = (s) => document.querySelector(s);
  const esc = (s) => s.replace(/[&<>"]/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;" }[c]));
  function code(text) {
    let html;
    try { html = window.hljs ? hljs.highlight(text, { language: "ruby", ignoreIllegals: true }).value : esc(text); }
    catch (e) { html = esc(text); }
    // One span per line, so that counters give line numbers; reopen spans that cross a newline.
    const out = []; let open = [];
    for (const line of html.split("\n")) {
      const prefix = open.join("");
      const tags = line.match(/<span[^>]*>|<\/span>/g) || [];
      for (const t of tags) { if (t === "</span>") open.pop(); else open.push(t); }
      out.push('<span class="ln">' + prefix + line + "</span>".repeat(open.length) + "</span>");
    }
    if (out.length && out[out.length - 1] === '<span class="ln"></span>') out.pop();
    return "<pre><code>" + out.join("") + "</code></pre>";
  }
  const ratio = (l) => l.sl / Math.max(l.rl, 1);
  function renderList() {
    const q = $("#filter").value.trim().toLowerCase();
    const s = $("#sort").value;
    const items = LIBS.filter((l) => l.name.includes(q));
    if (s === "ratio") items.sort((a, b) => ratio(b) - ratio(a));
    else if (s === "size") items.sort((a, b) => b.rl - a.rl);
    $("#list").innerHTML = items.map((l) =>
      `<li><button data-n="${l.name}" aria-current="${current === l.name}"><span>${l.name}</span><span class="r">${ratio(l).toFixed(2)}</span></button></li>`).join("") ||
      '<li class="empty">No library matches.</li>';
  }
  function render() {
    const l = LIBS.find((x) => x.name === current) || LIBS[0];
    if (!l) { $("#view").innerHTML = '<p class="empty">No libraries found.</p>'; return; }
    current = l.name;
    const notes = l.notes ? ` <a href="${REPO}sakelib/notes/${l.name}.md" target="_blank" rel="noopener">notes</a>` : "";
    let body;
    if (tab === "tests") {
      body = `<div class="cols">
        <div class="col ruby"><h3>Ruby <span>test/sakelib/${l.name}.rb · ${l.rl} lines</span></h3>${code(l.ruby)}</div>
        <div class="col sake"><h3>Sake <span>test/sakelib/${l.name}.sake · ${l.sl} lines</span></h3>${code(l.sake)}</div></div>`;
    } else {
      body = l.port ? `<div class="col sake"><h3>Sake port <span>sakelib/${l.name}.sake · ${l.pl} lines</span></h3>${code(l.port)}</div>`
                    : '<p class="empty">This test has no port file of the same name.</p>';
    }
    $("#view").innerHTML = `<div class="head"><h2>${l.name}</h2>
      <div class="chips"><span class="chip">Ruby <b>${l.rl}</b></span><span class="chip">Sake <b>${l.sl}</b></span>
      <span class="chip">ratio <b>${ratio(l).toFixed(2)}</b></span>${l.pl ? `<span class="chip">port <b>${l.pl}</b> lines</span>` : ""}</div>
      <span><a href="${REPO}sakelib/${l.name}.sake" target="_blank" rel="noopener">source</a>${notes}</span></div>
      <div class="tabs" role="tablist">
        <button role="tab" id="tab-tests" aria-selected="${tab === "tests"}" data-t="tests">Test programs</button>
        <button role="tab" id="tab-port" aria-selected="${tab === "port"}" data-t="port">Sake port</button></div>${body}`;
    renderList();
  }
  $("#list").addEventListener("click", (e) => {
    const b = e.target.closest("button[data-n]"); if (!b) return;
    current = b.dataset.n; render();
    try { history.replaceState(null, "", "#" + current); } catch (err) {}
  });
  $("#view").addEventListener("click", (e) => { const b = e.target.closest("button[data-t]"); if (b) { tab = b.dataset.t; render(); } });
  $("#filter").addEventListener("input", renderList);
  $("#sort").addEventListener("change", renderList);
  const h = location.hash.slice(1);
  current = LIBS.some((l) => l.name === h) ? h : (LIBS.find((l) => l.name === "json") || LIBS[0] || {}).name;
  render();
  </script>
HTML

page = <<~DOC + page + "</body>\n</html>\n" unless fragment
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  </head>
  <body>
DOC
File.write(out, page)
warn "wrote #{out}: #{libs.size} libraries, #{page.bytesize} bytes"
