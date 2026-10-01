# Statement-level delta reducer for TypeProf blow-ups.
# usage: ruby reduce.rb IN.rb OUT.rb MODE   (MODE: mem | crash:<regexp>)
# A candidate is kept iff (1) `ruby -c` accepts it, (2) `ruby cand.rb` exits 0 within 10 s,
# (3) the predicate holds: mem = typeprof still running at TO s with RSS > RSS_MB;
#     crash:<re> = typeprof output matches <re>.
require "prism"
require "tmpdir"
IN, OUT, MODE = ARGV
TO = (ENV["TO"] || 10).to_i
RSS_MB = (ENV["RSS_MB"] || 250).to_i
LOCK = File.open(File.join(__dir__, "..", ".tp.lock"), File::CREAT | File::RDWR)
$tests = 0

def runs?(path)
  system("ruby", "-c", path, out: File::NULL, err: File::NULL) &&
    system("timeout", "10", "ruby", path, out: File::NULL, err: File::NULL, chdir: File.dirname(path))
end

def interesting?(src)
  Dir.mktmpdir do |d|
    path = File.join(d, "t.rb")
    File.write(path, src)
    return false unless runs?(path)
    $tests += 1
    LOCK.flock(File::LOCK_EX)
    tm = File.join(d, "time")
    out = `bash -c 'ulimit -v 3000000; /usr/bin/time -v -o #{tm} timeout #{TO} typeprof --show-errors #{path} 2>&1'`
    rc = $?.exitstatus
    LOCK.flock(File::LOCK_UN)
    rss = File.read(tm)[/Maximum resident set size \(kbytes\): (\d+)/, 1] or raise "no rss"
    rss = rss.to_i / 1024
    if MODE == "mem"
      (rc == 124 && rss > RSS_MB) || out.include?("failed to allocate memory")
    else
      out.match?(Regexp.new(MODE.sub("crash:", "")))
    end
  end
end

# byte ranges (expanded to whole lines) of every statement in every StatementsNode
def candidates(src)
  res = []
  walk = ->(n) do
    if n.is_a?(Prism::StatementsNode)
      n.body.each do |s|
        st = src.rindex("\n", s.location.start_offset - 1)
        st = st ? st + 1 : 0
        en = src.index("\n", s.location.end_offset) || src.size
        res << [st, en + 1] if src[st...s.location.start_offset].strip.empty?
      end
    end
    n.compact_child_nodes.each { walk.(_1) }
  end
  walk.(Prism.parse(src).value)
  res.uniq.sort_by { |a, b| a - b } # biggest first
end

src = File.read(IN)
raise "original not interesting" unless interesting?(src)
loop do
  changed = false
  candidates(src).each do |st, en|
    cand = src[0...st] + src[en..].to_s
    next if cand == src
    if interesting?(cand)
      src = cand
      changed = true
      File.write(OUT, src)
      warn "[#{$tests}] removed lines -> #{src.lines.size} lines"
      break
    end
  end
  break unless changed
end
# drop comment / blank lines
s2 = src.lines.reject { _1.strip.empty? || _1.strip.start_with?("#") }.join
src = s2 if s2 != src && interesting?(s2)
File.write(OUT, src)
warn "done after #{$tests} typeprof runs: #{src.lines.size} lines"
