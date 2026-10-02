# For each error in classified.tsv (or only those with final cause = ARGV[0]), ask TypeProf (unpatched)
# the inferred type of the receiver and of each argument of the erroring call.
# usage: ruby typeinfo.rb [CAUSE] > runs/typeinfo.tsv   (path, error, receiver type, argument types)
require "typeprof"
require "json"
require_relative "static"
EXP = File.expand_path("../..", __dir__)
want = ARGV[0]
rows = File.readlines(File.join(__dir__, "classified.tsv")).drop(1).map { _1.chomp.split("\t") }
rows = rows.select { want.nil? || _1[4] == want }
CORE = TypeProf::Core::Service.new({})
lock = File.open(File.join(__dir__, "runs/.tplock"), File::CREAT | File::RDWR)
rows.group_by(&:first).each do |path, rs|
  file = File.join(EXP, path)
  lock.flock(File::LOCK_EX)
  rd, wr = IO.pipe
  pid = fork do
    rd.close
    Process.setrlimit(:CPU, 120)
    CORE.update_rb_file(file, File.read(file))
    tnode = CORE.instance_variable_get(:@rb_text_nodes)[file]
    by_off = {}
    tnode.traverse do |ev, n|
      next unless ev == :enter
      raw = n.instance_variable_get(:@raw_node)
      next unless raw.respond_to?(:location) && n.ret
      by_off[[raw.location.start_offset, raw.location.end_offset]] ||= n.ret
    end
    show = ->(pn) { v = pn && by_off[[pn.location.start_offset, pn.location.end_offset]]; v ? (v.show.empty? ? "(empty)" : v.show) : "?" }
    root = Prism.parse_file(file).value
    out = rs.map do |r|
      l, c, l2, c2, = Locate.parse_err(r[1])
      node, = Locate.node_at(root, l, c, l2, c2)
      recv = node.respond_to?(:receiver) ? node.receiver : nil
      args = node.respond_to?(:arguments) && node.arguments.respond_to?(:arguments) ? node.arguments.arguments : []
      args = [node.value] if node.respond_to?(:value) && !node.is_a?(Prism::CallNode)
      [path, r[1], recv ? show.(recv) : "-", args.map { show.(_1) }.join(" ; ")]
    end
    wr.write JSON.generate(out)
    exit!(0)
  end
  wr.close
  body = rd.read
  Process.wait(pid)
  lock.flock(File::LOCK_UN)
  (body.empty? ? rs.map { [path, _1[1], "FAILED", ""] } : JSON.parse(body)).each { puts _1.join("\t") }
end
