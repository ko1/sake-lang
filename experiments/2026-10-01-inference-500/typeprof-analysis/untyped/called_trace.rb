# frozen_string_literal: true

# Loaded with -r before a corpus program: records the Ruby-defined methods of the program's own file
# that ran, as "Class#name" (singleton methods as "Class.name"); writes JSON to $CALLED_OUT at exit.
require "json"
called = {}
main = File.expand_path($0)
TracePoint.new(:call) do |tp|
  next unless File.expand_path(tp.path) == main
  owner = tp.defined_class
  key = if owner.singleton_class?
          "#{owner.attached_object.is_a?(Module) ? Module.instance_method(:name).bind_call(owner.attached_object) : owner.inspect}.#{tp.method_id}"
        else
          "#{Module.instance_method(:name).bind_call(owner) || "Object"}##{tp.method_id}"
        end
  called[key] = true
end.enable
at_exit { File.write(ENV.fetch("CALLED_OUT"), JSON.generate(called.keys)) }
