require "fileutils"
require "pathname"
require "tmpdir"

# The test works in a temporary directory and shows paths relative to it.
def try(dir)
  yield
rescue SystemCallError => e
  puts "error"
rescue ArgumentError => e
  puts "ArgumentError: #{e.message.gsub(dir, "")}"
end

Dir.mktmpdir do |dir|
  f = ->(name) { File.join(dir, name) }
  tree = -> { Dir.glob("**/*", base: dir).sort }
  rel = ->(xs) { xs.map { |x| x.to_s.delete_prefix(dir) } }

  # touch
  p rel.(FileUtils.touch(f.("a")))
  p rel.(FileUtils.touch([f.("b"), f.("c")]))
  p FileUtils.touch(f.("d"), noop: true)
  p rel.(FileUtils.touch(Pathname.new(f.("a"))))
  try(dir) { FileUtils.touch(f.("d"), nocreate: true) }
  p tree.()
  p File.read(f.("a"))
  FileUtils.touch(f.("a"), mtime: Time.at(1000000000))
  p File.mtime(f.("a")).to_i
  FileUtils.touch(f.("new"), mtime: Time.at(2000000000))
  p File.mtime(f.("new")).to_i
  FileUtils.touch(f.("a"))
  p Time.now - File.mtime(f.("a")) < 3600
  p FileUtils.uptodate?(f.("a"), [f.("new")])
  p FileUtils.uptodate?(f.("new"), [f.("a")])
  p FileUtils.uptodate?(f.("a"), [f.("missing")])
  p FileUtils.uptodate?(f.("missing"), [f.("a")])

  # cp
  File.write(f.("a"), "alpha\n")
  p FileUtils.cp(f.("a"), f.("b"))
  p File.read(f.("b"))
  p FileUtils.cp(Pathname.new(f.("a")), Pathname.new(f.("c")), verbose: false)
  p File.read(f.("c"))
  try(dir) { FileUtils.cp(f.("a"), f.("a")) }
  try(dir) { FileUtils.cp(f.("missing"), f.("d")) }
  try(dir) { FileUtils.cp([f.("a"), f.("b")], f.("c")) }
  p FileUtils.cp(f.("a"), f.("d"), noop: true)
  p File.exist?(f.("d"))
  p FileUtils.compare_file(f.("a"), f.("b"))
  p FileUtils.identical?(f.("a"), f.("b"))
  File.write(f.("b"), "beta\n")
  p FileUtils.cmp(f.("a"), f.("b"))
  p FileUtils.copy(f.("a"), f.("c"))
  FileUtils.touch(f.("a"), mtime: Time.at(1500000000))
  FileUtils.cp(f.("a"), f.("pres"), preserve: true)
  p File.mtime(f.("pres")).to_i

  # binary content survives a copy
  File.write(f.("bin"), [0, 255, 10, 13, 128, 65].pack("C*"))
  FileUtils.copy_file(f.("bin"), f.("bin2"))
  p File.read(f.("bin2")).bytes
  p FileUtils.compare_file(f.("bin"), f.("bin2"))

  # mkdir_p / mkdir / rmdir
  p rel.(FileUtils.mkdir_p(f.("x/y/z")))
  p rel.(FileUtils.mkdir_p([f.("x/y"), f.("w/")]))
  p rel.(FileUtils.makedirs(f.("x")))
  p rel.(FileUtils.mkpath(Pathname.new(f.("v/u"))))
  p rel.(FileUtils.mkdir_p(f.("nodir"), noop: true))
  p File.exist?(f.("nodir"))
  try(dir) { FileUtils.mkdir_p(f.("a/sub")) }
  p rel.(FileUtils.mkdir(f.("m")))
  p rel.(FileUtils.mkdir([f.("m1"), f.("m2/")], mode: 0o755))
  try(dir) { FileUtils.mkdir(f.("m")) }
  try(dir) { FileUtils.mkdir(f.("q/r")) }
  p tree.()
  p rel.(FileUtils.rmdir(f.("m")))
  p rel.(FileUtils.rmdir([f.("m1"), f.("m2/")]))
  try(dir) { FileUtils.rmdir(f.("nodir")) }
  try(dir) { FileUtils.rmdir(f.("x")) }
  p FileUtils.rmdir(f.("nodir"), noop: true)
  p rel.(FileUtils.rmdir(f.("v/u"), parents: true))
  p File.exist?(f.("v"))
  p File.exist?(dir)

  # cp into a directory, cp_r, copy_entry
  FileUtils.cp([f.("a"), f.("b")], f.("x"))
  try(dir) { FileUtils.cp(f.("x"), f.("d")) }
  FileUtils.rm_f(f.("d"))   # Ruby leaves an empty d; Sake checks first
  p FileUtils.cp_r(f.("x"), f.("x2"))
  p FileUtils.cp_r(f.("x"), f.("w"))
  p FileUtils.copy_entry(f.("x/y"), f.("y2"))
  p tree.()

  # mv
  p FileUtils.mv(f.("b"), f.("d"))
  p [File.exist?(f.("b")), File.exist?(f.("d"))]
  p File.read(f.("d"))
  FileUtils.move(f.("d"), f.("b"))
  p File.read(f.("b"))
  FileUtils.mv([f.("b"), f.("c")], f.("w"))
  p FileUtils.mv(f.("x2"), f.("x3"))
  p FileUtils.mv(f.("y2"), f.("x3"))
  try(dir) { FileUtils.mv(f.("a"), f.("./a")) }
  try(dir) { FileUtils.mv(f.("missing"), f.("d")) }
  p FileUtils.mv(f.("a"), f.("d"), noop: true)
  p File.exist?(f.("a"))
  p tree.()

  # ln / ln_s / chmod
  p FileUtils.ln(f.("a"), f.("hard"))
  p File.read(f.("hard"))
  p FileUtils.ln_s("a", f.("soft"))
  p File.symlink?(f.("soft"))
  p File.readlink(f.("soft"))
  p File.read(f.("soft"))
  try(dir) { FileUtils.ln_s("b", f.("soft")) }
  p FileUtils.ln_sf("bin", f.("soft"))
  p File.readlink(f.("soft"))
  p FileUtils.ln_s(f.("bin"), f.("x"))
  p File.symlink?(f.("x/bin"))
  p rel.(FileUtils.chmod(0o755, f.("a")))
  p File.executable?(f.("a"))
  p rel.(FileUtils.chmod(0o644, [f.("a")]))
  p File.executable?(f.("a"))

  # rm / rm_f / rm_r / rm_rf
  p rel.(FileUtils.rm(f.("hard")))
  try(dir) { FileUtils.rm(f.("hard")) }
  p rel.(FileUtils.rm_f(f.("hard")))
  p rel.(FileUtils.rm_f([f.("hard"), f.("zz")]))
  p rel.(FileUtils.rm(f.("pres"), force: true))
  try(dir) { FileUtils.rm(f.("x")) }
  p rel.(FileUtils.rm_r(f.("x3")))
  try(dir) { FileUtils.rm_r(f.("x3")) }
  p rel.(FileUtils.rm_rf(f.("x3")))
  p rel.(FileUtils.rm_rf([f.("x"), f.("bin2")]))
  p rel.(FileUtils.rmtree(f.("w")))
  FileUtils.remove_entry(f.("soft"))
  FileUtils.remove_file(f.("bin"))
  FileUtils.remove_dir(f.("new"), true)
  p File.exist?(f.("new"))
  p rel.(FileUtils.safe_unlink([f.("a")]))
  p FileUtils.rm(f.("nofile"), noop: true)
  p tree.()
  p FileUtils.pwd == Dir.pwd
end
