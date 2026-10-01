# frozen_string_literal: true

# Classification of a structural type (see measure.rb), shared by measure.rb and typeprof_measure.rb.
# A structural type is an Array of atoms; an atom is a String (a type name) or [kind, children...],
# where for :tuple the child is [type, ...], for :record [[field, type], ...], and otherwise the
# children are types (Array[E] is [:array, E], Hash[K, V] is [:hash, K, V], Foo[A] is [:generic, "Foo", A]).
module Classify
  module_function

  RANK = %i[mono nilable union partial unknown].freeze

  def worst(*cs) = cs.max_by { RANK.index(_1) } || :mono

  def children(a)
    case a[0]
    when :tuple then a[1]
    when :record then a[1].map(&:last)
    when :generic then a.drop(2)
    else a.drop(1)
    end
  end

  # `top` distinguishes unknown (the whole type) from partial (unknown inside).
  def classify(sty, top: true)
    return(top ? :none : :mono) if sty.empty? # an element type nothing was written to
    return(top ? :unknown : :partial) if sty.include?([:unknown])
    non_nil = sty - ["Nil"]
    own = non_nil.size > 1 ? :union : (sty.include?("Nil") && non_nil.any? ? :nilable : :mono)
    inner = sty.flat_map { |a| a.is_a?(Array) ? children(a).map { classify(_1, top: false) } : [] }
    worst(own, *inner)
  end
end
