# frozen_string_literal: true

require_relative 'ast'
require_relative 'errors'

module SQL
  # Window calls in the AST and the WINDOW clause (SPEC 6.1, 6.2). This only reads the AST; running
  # them is in window_calculation.rb.
  module Windows
    module_function

    # Calls written identically (up to the case of names) are one window call.
    def key(call)
      window = call.window.is_a?(String) ? call.window.downcase : call.window
      WindowCall.new(call.call.with(name: call.call.name.downcase), window)
    end

    # The outermost window calls in `node`, each distinct one once, in order of appearance.
    def find_calls(node, found = {})
      case node
      when WindowCall then found[key(node)] ||= node
      when Subquery, Exists then nil # their windows belong to the subquery
      when InSelect then find_calls(node.expr, found)
      when Data then node.to_h.each_value { |v| find_calls(v, found) }
      when Array then node.each { |v| find_calls(v, found) }
      end
      found.values
    end

    # The WINDOW clause `definitions` ([[name, spec]]) as {lowercase name => spec with its base merged in}.
    def resolve_definitions(definitions)
      by_name = {}
      definitions.each do |name, spec|
        raise SqlError, "duplicate WINDOW name: #{name}" if by_name.key?(name.downcase)

        by_name[name.downcase] = spec
      end
      by_name.keys.to_h { |name| [name, resolve(by_name[name], by_name, [name])] }
    end

    # `window` (a WindowSpec or a name) with its base window merged in: a spec adds its own parts to
    # the parts of its base (SPEC 6.1). `definitions` is the WINDOW clause as {lowercase name => spec};
    # `visiting` guards against a window that is its own base.
    def resolve(window, definitions, visiting = [])
      spec = window.is_a?(String) ? WindowSpec.new(window, [], [], nil) : window
      return spec unless spec.base

      name = spec.base.downcase
      base = definitions[name]
      raise SqlError, "no such window: #{spec.base}" if base.nil? || visiting.include?(name)

      base = resolve(base, definitions, visiting + [name])
      WindowSpec.new(nil,
                     spec.partition_by.empty? ? base.partition_by : spec.partition_by,
                     spec.order_by.empty? ? base.order_by : spec.order_by,
                     spec.frame || base.frame)
    end
  end
end
