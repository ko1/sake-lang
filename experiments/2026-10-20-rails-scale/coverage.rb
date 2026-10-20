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
  head = File.foreach(path).first(8).join
  r = rows[gem]
  r[:sake] += code_lines(path)
  r[:files] += 1
  if head =~ /\(Sake only\)/
    r[:sake_only] += 1
    next
  end
  head = head.lines.take_while { _1.start_with?("#") }.join
  first = head[%r{[\w-]+-8\.1\.3/lib/[\w/]+\.rb}] or (problems << "#{f}: no 'Port of <gem>-8.1.3/lib/...' header"; next)
  # The directories a relative path may start from: the first file's, then each one up to lib/.
  bases = [File.dirname(first)]
  bases << File.dirname(bases.last) until bases.last.end_with?("/lib")
  r[:partial] += 1 if head.include?("(partial")
  # Paths after the first are relative to the same lib/ (`... methods.rb and inflector/*.rb`); globs expand.
  head.scan(%r{(?:[\w-]+-8\.1\.3/lib/)?[\w/*]+\.rb}).each do |spec|
    found = spec.include?("-8.1.3/") ? Dir.glob(File.join(GEMS, spec)) : bases.lazy.map { Dir.glob(File.join(GEMS, _1, spec)) }.find(&:any?) || []
    problems << "#{f}: cannot find #{spec}" if found.empty?
    found.each { r[:rb][_1] ||= code_lines(_1) }
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
