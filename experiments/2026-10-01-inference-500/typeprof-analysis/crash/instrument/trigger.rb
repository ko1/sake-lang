# Diagnostic only: log what wakes the max_by MethodCallBox (source vertex origin, added/removed types), first 12 events.
require "typeprof"
$trig = 0
TypeProf::Core::MethodCallBox.prepend(Module.new do
  [:on_type_added, :on_type_removed].each do |m|
    define_method(m) do |genv, src, tys|
      if @mid == :max_by && ($trig += 1) <= 12
        rets = []
        @a_args.block&.each_type { |ty| rets.concat(ty.block.next_boxes.map(&:a_ret)) if ty.is_a?(TypeProf::Core::Type::Proc) && ty.block.respond_to?(:next_boxes) }
        role = src.equal?(@a_args.block) ? "block-arg" : rets.any? { _1.equal?(src) } ? "block-return-vertex" : src.equal?(@recv) ? "receiver" : "other"
        $stderr.puts "TRIG #{m} from #{role} vertex types=#{tys.map(&:show)}"
      end
      super(genv, src, tys)
    end
  end
end)
