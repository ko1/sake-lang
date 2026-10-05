# Level-1 errors and `mixed` warnings per corpus: ruby -Ilib level_counts.rb FILE.sake...
require "sake"; require "sake/cli"; require "sake/typer"; require "stringio"
err_progs = err = warn_progs = warns = 0
ARGV.each do |f|
  prog = Sake.load(File.read(f), f, out: StringIO.new) rescue next
  t = Sake::Typer.new(prog).run
  e = Sake::CLI.strict_diagnostics(prog, Sake::CLI::STRICT_LEVELS[1], t).size
  w = Sake::CLI.strict_diagnostics(prog, Sake::CLI::WARN_ITEMS, t).size
  err += e; err_progs += 1 if e.positive?
  warns += w; warn_progs += 1 if w.positive?
end
puts "level 1: #{err_progs} programs / #{err} errors; mixed warnings: #{warn_progs} programs / #{warns}"
