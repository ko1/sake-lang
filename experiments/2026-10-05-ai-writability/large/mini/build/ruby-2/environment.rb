require_relative "errors"

module Mini
  # A run-time scope. Run-time scopes correspond one to one with the static
  # scopes of section 5.1, so a name is found by going up the number of scopes
  # the static checks computed (`hops`) and looking it up there. A variable
  # that is missing at that scope has not been declared yet (section 6.4).
  class Environment
    attr_reader :parent

    def initialize(parent = nil)
      @parent = parent
      @vars = {}
    end

    def define(name, value)
      @vars[name] = value
    end

    def lookup(name, hops)
      scope = ancestor(hops)
      scope.declared!(name)
      scope.vars_get(name)
    end

    def assign(name, hops, value)
      scope = ancestor(hops)
      scope.declared!(name)
      scope.define(name, value)
    end

    protected

    def vars_get(name) = @vars[name]

    def declared!(name)
      return if @vars.key?(name)
      raise Fault.new("name", "'#{name}' is used before its declaration")
    end

    private

    def ancestor(hops)
      scope = self
      hops.times { scope = scope.parent }
      scope
    end
  end
end
