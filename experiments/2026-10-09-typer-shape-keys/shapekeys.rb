$LOAD_PATH.unshift("/home/ko1/app/sake/lib")
require "sake"; require "sake/typer"; require "stringio"
path, name = ARGV
program = Sake.load(File.read(path), path, out: StringIO.new)
by_id = program.functions.values.flat_map(&:values).to_h { [_1.__id__, _1] }
Sake::Typer::SHAPE_KEYS[0] = true
t = Sake::Typer.new(program).run
insts = t.instance_variable_get(:@insts)
fn = by_id.values.find { _1.full_name == name }
puts "#{name} shape_ok=#{t.shape_ok(fn).inspect} params=#{fn.params.inspect}"
keys = insts.keys.select { _1[0] == fn.__id__ }
desc = lambda do |id|
  o = ObjectSpace._id2ref(id) rescue (return "?")
  if o.is_a?(Array) && o.any? { _1.is_a?(Array) && _1[0].to_s.end_with?("_shape") }
    o.map { |a| a.is_a?(Array) && a[0].to_s.end_with?("_shape") ? "#{a[0]}[" + a.drop(1).map { |x| x.is_a?(Integer) ? (e = (ObjectSpace._id2ref(x) rescue nil); e.is_a?(Array) ? t.show(e)[0, 60] : x.inspect) : x.inspect }.join(" / ") + "]" : t.show([a]) }.join(" | ")
  else
    t.show(o)[0, 70]
  end
end
keys.first(12).each { |k| puts "  " + k.drop(1).map { desc.(_1) }.join(" ;; ") }
puts "  total #{keys.size}"
