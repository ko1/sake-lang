# frozen_string_literal: true

# Controls for Mini change tasks (P6): ruby validate_mini_change.rb CHANGE_DIR...   (large/mini/changes/mNN-*)
# For each codebase (ruby, sake = the port, sake-scratch):
#   positive: ref/<codebase>/ passes every test in CHANGE_DIR/tests (Sake: --strict=2 -c first);
#   the change matters: the base codebase fails at least 2 of them;
# and over all three: kept = tests every base passes (behaviour the change leaves alone), at least 100.
# Also the functions the reference diff touches, per codebase (touched_defs, see Defs below): the ground
# truth for "every place the change must reach". One JSON line per change; exit 1 when a check fails.
require_relative "common"

MINI = File.join(AW::EXP, "large", "mini")
BASES = { "ruby" => "ruby", "sake" => "sake", "sake-scratch" => "sake-scratch" }.freeze

def ext_of(codebase) = codebase == "ruby" ? "rb" : "sake"

# [passed names, failed names] of running dir/main.<ext> on every test in tests_dir
def run_suite(dir, ext, tests_dir)
  main = File.join(dir, "main.#{ext}")
  if ext == "sake"
    _o, _e, st = AW.run([AW::SAKE, "--strict=2", "-c", main], "", 600) # the port's check takes ~25 s
    return [[], Dir[File.join(tests_dir, "*.mini")].map { File.basename(_1, ".mini") }, :check_failed] unless st == 0
  end
  cmd = ext == "sake" ? [AW::SAKE, "--strict=0", main] : ["ruby", main]
  pass, fail = Dir[File.join(tests_dir, "*.mini")].sort.partition do |t|
    out, _e, st = AW.run(cmd, File.read(t))
    st == 0 && out == File.read(t.sub(/\.mini\z/, ".out"))
  end
  [pass.map { File.basename(_1, ".mini") }, fail.map { File.basename(_1, ".mini") }, nil]
end

module Defs
  DEF = /\A\s*def\s+([A-Za-z_][\w.]*[?!=]?)/
  ENDLESS = /\A\s*def\s+[A-Za-z_][\w.]*[?!]?(\([^)]*\))?\s*=(?![=~])/
  NAMESPACE = /\A\s*(?:class|module)\s+([A-Z]\w*)/
  module_function

  # "file:def" for every changed or added line of new (and every removed line of old), comments and blank
  # lines excepted, by the enclosing
  # def (the nearest def above with less or equal indentation); lines outside any def count as "file:<top>".
  def touched(old_file, new_file)
    label = File.basename(new_file || old_file)
    return ["#{label}:<new file>"] if old_file.nil?
    return ["#{label}:<removed file>"] if new_file.nil?
    out, _e, _s = AW.run(["diff", old_file, new_file], "")
    old_lines, new_lines = File.readlines(old_file), File.readlines(new_file)
    out.lines.grep(/\A\d/).flat_map do |h|
      h =~ /\A(\d+)(?:,(\d+))?([acd])(\d+)(?:,(\d+))?/
      o1, o2, kind, n1, n2 = $1.to_i, ($2 || $1).to_i, $3, $4.to_i, ($5 || $4).to_i
      olds = kind == "a" ? [] : (o1..o2).reject { blank_or_comment?(old_lines[_1 - 1]) }.map { enclosing(old_lines, _1) }
      news = kind == "d" ? [] : (n1..n2).reject { blank_or_comment?(new_lines[_1 - 1]) }.map { enclosing(new_lines, _1) }
      (olds + news).map { "#{label}:#{_1}" }
    end.uniq
  end

  # comments, blank lines and a bare `end` are not behaviour of their own; a bare `end` is also where diff
  # aligns an inserted function with the end of the one above it, which would credit the wrong def
  def blank_or_comment?(line) = (t = line.to_s.strip).empty? || t.start_with?("#") || t == "end"

  def enclosing(lines, lineno)
    indent = lines[lineno - 1].to_s[/\A\s*/].size
    (lineno - 1).downto(0) do |i|
      ind = lines[i][/\A\s*/].size
      if (m = DEF.match(lines[i]))
        # a one-line `def f(...) = expr` encloses only its own line
        next if i != lineno - 1 && lines[i].match?(ENDLESS)
        return m[1] if ind <= indent
      elsif (c = NAMESPACE.match(lines[i])) && ind < indent
        return "#{c[1]}:<body>" # attr_* lines and the like, outside any def
      end
    end
    "<top>"
  end
end

if $PROGRAM_NAME == __FILE__
  write_kept = ARGV.delete("--write-kept") # also write CHANGE_DIR/kept.txt (the regression suite of make_mini_run.rb)
  bad = false
  ARGV.each do |dir|
    tests = File.join(dir, "tests")
    rec = { change: File.basename(dir), tests: Dir[File.join(tests, "*.mini")].size }
    kept = nil
    BASES.each do |name, base_dir|
      ext = ext_of(name)
      ref = File.join(dir, "ref", name)
      rp, rf, rerr = run_suite(ref, ext, tests)
      bp, bf, = run_suite(File.join(MINI, base_dir), ext, tests)
      kept = kept ? kept & bp : bp
      files = (Dir[File.join(MINI, base_dir, "*.#{ext}")].map { File.basename(_1) } | Dir[File.join(ref, "*.#{ext}")].map { File.basename(_1) }).sort
      defs = files.flat_map do |f|
        o, n = File.join(MINI, base_dir, f), File.join(ref, f)
        next [] if File.exist?(o) && File.exist?(n) && File.read(o) == File.read(n)
        Defs.touched(File.exist?(o) ? o : nil, File.exist?(n) ? n : nil)
      end
      rec[name] = { ref_ok: rf.empty? && rerr.nil?, ref_fail: rf.first(10), ref_check: rerr, base_fails: bf.size,
                    diff_lines: files.sum { |f| File.exist?(File.join(ref, f)) && File.exist?(File.join(MINI, base_dir, f)) ? AW.diff_lines(File.join(MINI, base_dir, f), File.join(ref, f)) : 0 },
                    files_touched: defs.map { _1.split(":").first }.uniq.size, touched_defs: defs }
    end
    rec[:kept] = kept.size
    File.write(File.join(dir, "kept.txt"), kept.sort.join("\n") + "\n") if write_kept
    rec[:ok] = BASES.keys.all? { rec[_1][:ref_ok] && rec[_1][:base_fails] >= 2 } && kept.size >= 100
    bad ||= !rec[:ok]
    puts JSON.generate(rec)
  end
  exit(bad ? 1 : 0)
end
