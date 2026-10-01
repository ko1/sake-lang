# frozen_string_literal: true

# Loaded with -r before a corpus program: records, for each call in the program's own file, the classes
# of the receivers seen at run time, keyed by (line, method). Writes JSON to $RECEIVER_TRACE_OUT at exit.
# Specialized instructions are off so that operators (a + b) are traced as calls too.
require "json"
RubyVM::InstructionSequence.compile_option = { specialized_instruction: false }
sites = Hash.new { |h, k| h[k] = {} }
main = File.expand_path($0)
TracePoint.new(:call, :c_call) do |tp|
  loc = caller_locations(2, 1)&.first
  next unless loc && loc.absolute_path == main
  sites["#{loc.lineno} #{tp.method_id}"][tp.self.class.name || tp.self.class.inspect] = true
end.enable
at_exit { File.write(ENV.fetch("RECEIVER_TRACE_OUT"), JSON.generate(sites.transform_values(&:keys))) }
