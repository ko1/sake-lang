class DirNode
  attr_reader :name, :parent, :subdirs, :files

  def initialize(name, parent)
    @name = name
    @parent = parent
    @subdirs = {}
    @files = []
  end

  def path
    return "/" if parent.nil?
    pp = parent.path
    pp == "/" ? "/#{name}" : "#{pp}/#{name}"
  end

  def mkdir_p(parts)
    parts.reduce(self) { |d, name| d.subdirs[name] ||= DirNode.new(name, d) }
  end

  def total
    own = files.sum(&:size)
    subdirs.values.reduce(own) { |acc, s| acc + s.total }
  end

  def each_dir(&block)
    yield self
    subdirs.each_value { |s| s.each_dir(&block) }
  end
end

class FileEntry
  attr_reader :name, :size, :dir

  def initialize(name, size, dir)
    @name = name
    @size = size
    @dir = dir
  end
end

class NotFound < StandardError
  attr_reader :path

  def initialize(message, path)
    super(message)
    @path = path
  end
end

def human(n)
  return "#{n}B" if n < 1024
  return format("%.1fK", n / 1024.0) if n < 1024 * 1024
  format("%.1fM", n / (1024.0 * 1024))
end

def resolve(root, cwd, path)
  d = path.start_with?("/") ? root : cwd
  path.split("/").each do |part|
    next if part == "" || part == "."
    if part == ".."
      d = d.parent if d.parent
    else
      nxt = d.subdirs[part]
      raise NotFound.new("no such directory: #{path}", path) if nxt.nil?
      d = nxt
    end
  end
  d
end

def print_tree(d, indent, max_depth)
  label = indent == "" ? "/" : "#{d.name}/"
  puts format("%-28s %8s", indent + label, human(d.total))
  return if indent.size / 2 >= max_depth
  d.subdirs.values.sort_by { |s| -s.total }.each { |s| print_tree(s, indent + "  ", max_depth) }
  puts format("%-28s %8s", indent + "  (#{d.files.size} files)", "") if d.files.size > 0
end

listing = <<~LS
  /etc/hosts 220
  /etc/nginx/nginx.conf 2400
  /etc/nginx/sites/default.conf 900
  /etc/nginx/sites/api.conf 1300
  /home/ann/notes.txt 5300
  /home/ann/photos/cat.jpg 840000
  /home/ann/photos/dog.jpg 1250000
  /home/ann/photos/raw/IMG_0001.cr2 9800000
  /home/bob/.bashrc 3100
  /home/bob/src/app/main.rb 12000
  /home/bob/src/app/util.rb 4100
  /home/bob/src/app/test/main_test.rb 7700
  /home/bob/src/lib/parser.rb 26000
  /var/log/syslog 3400000
  /var/log/nginx/access.log 2100000
  /var/log/nginx/error.log 64000
  /var/cache/apt/pkgcache.bin 31000000
LS

root = DirNode.new("", nil)
all_files = []
listing.each_line do |line|
  path, size = line.strip.split(" ")
  *parts, name = path.split("/").drop(1)
  dir = root.mkdir_p(parts)
  f = FileEntry.new(name, size.to_i, dir)
  dir.files << f
  all_files << f
end

print_tree(root, "", 3)

puts "-- directories over 1M --"
big = []
root.each_dir { |d| big << d if d.total > 1024 * 1024 }
big.sort_by(&:path).each { |d| puts format("  %-24s %s", d.path, human(d.total)) }

puts "-- largest files --"
all_files.sort_by { |f| -f.size }.take(3).each { |f| puts "  #{f.dir.path}/#{f.name} #{human(f.size)}" }

puts "-- by extension --"
by_ext = Hash.new(0)
all_files.each do |f|
  dot = f.name.rindex(".")
  ext = dot.nil? || dot == 0 ? "(none)" : f.name[(dot + 1)..]
  by_ext[ext] += f.size
end
by_ext.sort_by { |_e, s| -s }.each { |e, s| puts format("  %-7s %s", e, human(s)) }

puts "-- navigation --"
cwd = resolve(root, root, "/home/bob/src")
["app/test", "../..", "../../ann/photos/raw", "/var/log/nginx", "lib/missing", "/../etc"].each do |p|
  target = resolve(root, cwd, p)
  puts "  cd #{p} -> #{target.path} (#{human(target.total)})"
rescue NotFound => e
  puts "  cd #{p} -> error: #{e.message}"
end
