# How much of Rails 8.1.3 is ported: reads the header of every sakelib/rails/**/*.sake
# ("# Port of <gem>-8.1.3/lib/<path>.rb[, <path>.rb ...] (partial: ...)" or "(Sake only)") and prints, per gem,
# the Ruby code lines of the files named, the Sake code lines, and the gem's whole lib/ for scale.
# Code lines: not blank and not only a comment. A partial port counts its Ruby file whole (marked "partial").
# usage: ruby coverage.rb [--files]
GEMS = File.expand_path("~/.rbenv/versions/4.0.2/lib/ruby/gems/4.0.0/gems")
ROOT = File.expand_path("../../sakelib/rails", __dir__)

def code_lines(path) = File.foreach(path).count { |l| l !~ /\A\s*(#.*)?\Z/ }

files = Dir.glob("**/*.sake", base: ROOT).sort
rows = Hash.new { |h, k| h[k] = { ruby: 0, sake: 0, files: 0, partial: 0, sake_only: 0, rb: {} } }
problems = []
files.each do |f|
  path = File.join(ROOT, f)
  gem = f.split("/").first
  head = File.foreach(path).first(3).join
  r = rows[gem]
  r[:sake] += code_lines(path)
  r[:files] += 1
  if head =~ /\(Sake only\)/
    r[:sake_only] += 1
    next
  end
  m = head.match(/# Port of (.+?)(?: \(partial[^)]*\))?\s*$/) or (problems << "#{f}: no 'Port of' header"; next)
  r[:partial] += 1 if head.include?("(partial")
  m[1].split(/,\s*/).each do |spec|
    spec = spec.sub(/ \(.*\z/, "")
    full = spec.include?("-8.1.3/") ? File.join(GEMS, spec) : nil
    if full.nil? || !File.file?(full)
      problems << "#{f}: cannot find #{spec}"
      next
    end
    r[:rb][full] ||= code_lines(full)
  end
end

printf("%-16s %6s %8s %8s %8s %10s\n", "gem", "files", "partial", "ruby", "sake", "gem lib/")
total = [0, 0, 0]
rows.sort.each do |gem, r|
  ruby = r[:rb].values.sum
  lib = Dir.glob(File.join(GEMS, "#{gem}-8.1.3/lib/**/*.rb")).sum { code_lines(_1) }
  printf("%-16s %6d %8d %8d %8d %10d\n", gem, r[:files], r[:partial], ruby, r[:sake], lib)
  total[0] += ruby
  total[1] += r[:sake]
  total[2] += lib
end
printf("%-16s %6s %8s %8d %8d %10d\n", "total", "", "", *total)
if ARGV.include?("--files")
  rows.sort.each { |gem, r| r[:rb].sort.each { |p, n| printf("  %6d %s\n", n, p.delete_prefix(GEMS + "/")) } }
end
warn problems.join("\n") unless problems.empty?
