#!/usr/bin/env ruby
# frozen_string_literal: true

# Assembles the GitHub Pages site (.github/workflows/pages.yml runs it after docs/manual/build.sh):
#   index.html   README.md rendered with kramdown; links into the repository point at GitHub,
#                docs/manual/ and docs/guide.html point at the copies below
#   manual/      docs/manual/build (the ligarb book, ja/en)
#   guide.html   docs/guide.html
# usage: ruby tools/gen_site.rb [OUT_DIR]   (default: _site)

require "fileutils"
require "kramdown"
require "kramdown-parser-gfm"

ROOT = File.expand_path("..", __dir__)
REPO = "https://github.com/ko1/sake-lang"
out = File.expand_path(ARGV[0] || "_site", Dir.pwd)

book = File.join(ROOT, "docs/manual/build/index.html")
abort "#{book} is missing: run sh docs/manual/build.sh first" unless File.exist?(book)

# A relative link in README.md: the two documents that live on this site keep a local path,
# everything else goes to the repository (a file to blob/, a directory to tree/).
def rewrite(href)
  return href if href.start_with?("http://", "https://", "#", "mailto:")
  return "manual/" if href == "docs/manual/"
  return "guide.html" if href == "docs/guide.html"
  path, frag = href.split("#", 2)
  kind = File.directory?(File.join(ROOT, path)) ? "tree" : "blob"
  "#{REPO}/#{kind}/main/#{path}#{frag ? "##{frag}" : ""}"
end

readme = File.read(File.join(ROOT, "README.md"))
body = Kramdown::Document.new(readme, input: "GFM", hard_wrap: false, auto_ids: true).to_html
body = body.gsub(/href="([^"]*)"/) { %(href="#{rewrite(Regexp.last_match(1))}") }

page = <<~HTML
  <!doctype html>
  <html lang="en">
  <head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sake-lang</title>
  <meta name="description" content="Sake: Ruby's syntax with the type written on every operation. An experimental language, concluded 2026-10-08.">
  <style>
  :root { --bg: #fbfbf9; --fg: #22272e; --muted: #5b6672; --rule: #d9dde2; --accent: #1f6f78; --code-bg: #eef0f2; color-scheme: light; }
  @media (prefers-color-scheme: dark) { :root { --bg: #14191e; --fg: #e4e8ec; --muted: #9aa6b2; --rule: #2b343d; --accent: #6fc3cb; --code-bg: #1f272f; color-scheme: dark; } }
  body { margin: 0; padding: 0 16px 4rem; background: var(--bg); color: var(--fg); line-height: 1.65;
         font: 16px/1.65 -apple-system, "Segoe UI", "Helvetica Neue", "Hiragino Sans", "Noto Sans JP", sans-serif; }
  main { max-width: 46rem; margin: 0 auto; }
  nav { display: flex; flex-wrap: wrap; gap: 0.4rem 1.4rem; align-items: baseline; padding: 1rem 0; border-bottom: 1px solid var(--rule); font-size: 0.95rem; }
  nav .name { font-weight: 700; margin-right: auto; }
  nav a { color: var(--accent); text-decoration: none; }
  nav a:hover { text-decoration: underline; }
  a { color: var(--accent); }
  h1, h2, h3 { line-height: 1.3; text-wrap: balance; }
  h1 { font-size: 2rem; margin-top: 1.6rem; }
  h2 { font-size: 1.4rem; margin-top: 2.4rem; padding-bottom: 0.2rem; border-bottom: 1px solid var(--rule); }
  h3 { font-size: 1.1rem; margin-top: 1.8rem; }
  pre, code { font-family: ui-monospace, "SFMono-Regular", Menlo, Consolas, monospace; font-size: 0.9em; }
  code { background: var(--code-bg); padding: 0.1em 0.3em; border-radius: 3px; }
  pre { background: var(--code-bg); padding: 0.8rem 1rem; border-radius: 4px; overflow-x: auto; line-height: 1.5; }
  pre code { background: none; padding: 0; }
  li { margin: 0.3rem 0; }
  footer { margin-top: 3rem; padding-top: 1rem; border-top: 1px solid var(--rule); color: var(--muted); font-size: 0.85rem; }
  </style>
  </head>
  <body>
  <main>
  <nav>
    <span class="name">Sake-lang</span>
    <a href="manual/">Reference manual (日本語 / English)</a>
    <a href="guide.html">Guide</a>
    <a href="#{REPO}">GitHub</a>
  </nav>
  #{body}
  <footer>This page is <a href="#{REPO}/blob/main/README.md">README.md</a> of the repository, rendered by tools/gen_site.rb.</footer>
  </main>
  </body>
  </html>
HTML

FileUtils.rm_rf(out)
FileUtils.mkdir_p(out)
File.write(File.join(out, "index.html"), page)
FileUtils.cp_r(File.dirname(book), File.join(out, "manual"))
FileUtils.cp(File.join(ROOT, "docs/guide.html"), File.join(out, "guide.html"))
FileUtils.touch(File.join(out, ".nojekyll"))
puts "Built #{out}: index.html, manual/, guide.html"
