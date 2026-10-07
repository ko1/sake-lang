# A scope at run time: the variables of one block, call, loop iteration or catch,
# and the scope it is nested in. Variables are found by the depth the resolver
# computed, so a variable declared later in an inner scope never captures a
# name that was resolved to an outer one.
class Env
  attr_reader :vars, :parent

  def initialize(parent)
    @vars = {}
    @parent = parent
  end

  def define(name, value)
    @vars[name] = value
    nil
  end

  def lookup(depth, name, pos)
    vars = vars_at(depth)
    uninitialized(name, pos) unless vars.key?(name)
    vars[name]
  end

  def assign(depth, name, value, pos)
    vars = vars_at(depth)
    uninitialized(name, pos) unless vars.key?(name)
    vars[name] = value
    nil
  end

  # The variables of the scope `depth` levels out (0 = this one).
  def vars_at(depth) = depth == 0 ? @vars : @parent.vars_at(depth - 1)

  private

  # Possible only when a function, visible in its whole block, is called before
  # a `let` that precedes its declaration (and that it uses) has run.
  def uninitialized(name, pos)
    Errors.runtime("name", "'#{name}' is used before its declaration", pos)
  end
end
