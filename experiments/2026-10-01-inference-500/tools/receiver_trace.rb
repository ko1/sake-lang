# frozen_string_literal: true

# Loaded with -r before a corpus program: records, for each call in the program's own file, the classes
# of the receivers seen at run time, keyed by (line, method). Writes JSON to $RECEIVER_TRACE_OUT at exit.
# Specialized instructions are off so that operators (a + b) are traced as calls too.
require "json"
RubyVM::InstructionSequence.compile_option = { specialized_instruction: false }
sites = Hash.new { |h, k| h[k] = {} }
main = File.expand_path($0)
# For a C method (c_call) the event's own path/line is the calling line; for a Ruby method (call) it
# is the method's definition, so the calling line is the caller's frame. A C method called by another
# C method (String#match calling Regexp#match) is not a call the program wrote: `stack` tracks whether
# the innermost running code is Ruby (:rb) or C (:c).
stack = []
TracePoint.new(:call, :c_call, :b_call, :return, :c_return, :b_return) do |tp|
  case tp.event
  when :c_call
    inner_c = stack.last == :c
    stack << :c
    next if inner_c
    path = File.expand_path(tp.path)
    line = tp.lineno
  when :call
    stack << :rb
    loc = caller_locations(2, 1)&.first or next
    path = loc.absolute_path
    line = loc.lineno
  when :b_call
    stack << :rb
    next
  else
    stack.pop
    next
  end
  next unless path == main
  sites["#{line} #{tp.method_id}"][tp.self.class.name || tp.self.class.inspect] = true
end.enable
at_exit { File.write(ENV.fetch("RECEIVER_TRACE_OUT"), JSON.generate(sites.transform_values(&:keys))) }
