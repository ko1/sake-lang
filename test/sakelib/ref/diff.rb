# Reference implementation for sakelib/diff.sake: the diff-lcs gem's API (Diff::LCS.lcs, diff, sdiff,
# patch, unpatch, traverse_sequences, traverse_balanced), with a dynamic-programming LCS.
module Diff
  module LCS
    class Change
      attr_reader :action, :position, :element

      def initialize(action, position, element)
        @action = action
        @position = position
        @element = element
      end

      def to_a = [@action, @position, @element]
      def inspect = "#<Diff::LCS::Change: #{to_a.inspect}>"
      def adding? = @action == "+"
      def deleting? = @action == "-"
      def unchanged? = @action == "="
    end

    class ContextChange
      attr_reader :action, :old_position, :old_element, :new_position, :new_element

      def initialize(action, old_position, old_element, new_position, new_element)
        @action = action
        @old_position = old_position
        @old_element = old_element
        @new_position = new_position
        @new_element = new_element
      end

      def to_a = [@action, [@old_position, @old_element], [@new_position, @new_element]]
      def inspect = "#<Diff::LCS::ContextChange: #{to_a.inspect}>"
      def adding? = @action == "+"
      def deleting? = @action == "-"
      def unchanged? = @action == "="
      def changed? = @action == "!"
    end

    module_function

    def seq(x) = x.is_a?(String) ? x.chars : x

    def matches(a, b)
      n = a.size
      m = b.size
      len = Array.new(n + 1) { Array.new(m + 1, 0) }
      (n - 1).downto(0) do |i|
        (m - 1).downto(0) do |j|
          len[i][j] = a[i] == b[j] ? len[i + 1][j + 1] + 1 : [len[i + 1][j], len[i][j + 1]].max
        end
      end
      out = []
      i = j = 0
      while i < n && j < m
        if a[i] == b[j]
          out << [i, j]
          i += 1
          j += 1
        elsif len[i + 1][j] >= len[i][j + 1]
          i += 1
        else
          j += 1
        end
      end
      out
    end

    def lcs(a, b)
      sa = seq(a)
      matches(sa, seq(b)).map { |i, _| sa[i] }
    end

    def traverse_sequences(a, b)
      sa = seq(a)
      sb = seq(b)
      i = j = 0
      (matches(sa, sb) << [sa.size, sb.size]).each do |mi, mj|
        while i < mi
          yield :discard_a, i, j
          i += 1
        end
        while j < mj
          yield :discard_b, i, j
          j += 1
        end
        next unless mi < sa.size
        yield :match, i, j
        i += 1
        j += 1
      end
      nil
    end

    def traverse_balanced(a, b)
      sa = seq(a)
      sb = seq(b)
      i = j = 0
      (matches(sa, sb) << [sa.size, sb.size]).each do |mi, mj|
        while i < mi || j < mj
          if i < mi && j < mj
            yield :change, i, j
            i += 1
            j += 1
          elsif i < mi
            yield :discard_a, i, j
            i += 1
          else
            yield :discard_b, i, j
            j += 1
          end
        end
        next unless mi < sa.size
        yield :match, i, j
        i += 1
        j += 1
      end
      nil
    end

    def diff(a, b)
      sa = seq(a)
      sb = seq(b)
      hunks = []
      hunk = []
      traverse_sequences(sa, sb) do |kind, i, j|
        case kind
        when :match
          hunks << hunk unless hunk.empty?
          hunk = []
        when :discard_a then hunk << Change.new("-", i, sa[i])
        when :discard_b then hunk << Change.new("+", j, sb[j])
        end
      end
      hunks << hunk unless hunk.empty?
      hunks
    end

    SDIFF_ACTIONS = { match: "=", change: "!", discard_a: "-", discard_b: "+" }.freeze

    def sdiff(a, b)
      sa = seq(a)
      sb = seq(b)
      out = []
      traverse_balanced(sa, sb) do |kind, i, j|
        old = kind == :discard_b ? nil : sa[i]
        nw = kind == :discard_a ? nil : sb[j]
        out << ContextChange.new(SDIFF_ACTIONS.fetch(kind), i, old, j, nw)
      end
      out
    end

    def patch(src, patchset) = apply(src, patchset, false)
    def unpatch(src, patchset) = apply(src, patchset, true)

    def apply(src, patchset, reverse)
      s = seq(src)
      res = []
      ai = bj = 0
      patchset.flatten.each do |c|
        case c
        when Change
          action = c.action
          action = action == "+" ? "-" : "+" if reverse
          if action == "-"
            while ai < c.position
              res << s[ai]
              ai += 1
              bj += 1
            end
            ai += 1
          else
            while bj < c.position
              res << s[ai]
              ai += 1
              bj += 1
            end
            bj += 1
            res << c.element
          end
        when ContextChange
          action = c.action
          op = c.old_position
          np = c.new_position
          el = c.new_element
          if reverse
            action = { "+" => "-", "-" => "+" }.fetch(action, action)
            op, np = np, op
            el = c.old_element
          end
          while ai < op && bj < np
            res << s[ai]
            ai += 1
            bj += 1
          end
          case action
          when "-" then ai += 1
          when "+"
            res << el
            bj += 1
          when "!"
            res << el
            ai += 1
            bj += 1
          else
            res << s[ai]
            ai += 1
            bj += 1
          end
        end
      end
      while ai < s.size
        res << s[ai]
        ai += 1
      end
      src.is_a?(String) ? res.join : res
    end
  end
end
