# A plain-Ruby reference for sakelib/rspec.sake: RSpec's DSL (describe / context / it / xit / pending,
# expect(x).to matcher, expect { }.to raise_error) and its documentation format, without the timing
# line and the "Failed examples" list, as the Sake version prints them. The real rspec gem is not
# installed here, and its output has colours and timings.

module RSpecRef
  class ExpectationNotMet < StandardError; end
  class Pending < StandardError; end

  LINES = []
  RESULTS = []
  GROUPS = []

  class Group
    attr_reader :description, :depth, :full_description
    def initialize(description, depth, full)
      @description, @depth, @full_description = description, depth, full
    end
    def indent = "  " * (@depth + 1)

    def context(description, &blk)
      child = Group.new(description, @depth + 1, "#{@full_description} #{description}")
      LINES << indent + description
      child.instance_eval(&blk)
      child
    end

    def record(description, status, message)
      RESULTS << ["#{@full_description} #{description}", status, message]
      line = indent + description
      if status == :failed
        line += " (FAILED - #{RESULTS.count { |r| r[1] == :failed }})"
      elsif status == :pending
        line += " (PENDING: #{message})"
      end
      LINES << line
      nil
    end

    def it(description, &blk)
      return record(description, :pending, "Not yet implemented") unless blk
      ex = Example.new
      begin
        ex.instance_eval(&blk)
        record(description, :passed, "")
      rescue ExpectationNotMet, StandardError => e
        if e.is_a?(Pending)
          record(description, :pending, e.message)
        else
          record(description, :failed, e.message)
        end
      end
      nil
    end

    def xit(description, &blk) = record(description, :pending, "Temporarily skipped with xit")
  end

  class Example
    include Kernel
    def expect(actual = nil, &blk) = Expectation.new(blk || actual, !blk.nil?)
    def pending(reason = "No reason given") = raise(Pending, reason)
    def skip(reason = "No reason given") = raise(Pending, reason)

    def eq(x) = Matcher.new(:eq, x)
    def eql(x) = Matcher.new(:eq, x)
    def be(x = :__none) = x == :__none ? BeMatcher.new : Matcher.new(:be, x)
    def be_truthy = Matcher.new(:be_truthy)
    def be_falsey = Matcher.new(:be_falsey)
    def be_falsy = Matcher.new(:be_falsey)
    def be_nil = Matcher.new(:be_nil)
    def include(*xs) = Matcher.new(:include, xs)
    def match(re) = Matcher.new(:match, re)
    def start_with(s) = Matcher.new(:start_with, s)
    def end_with(s) = Matcher.new(:end_with, s)
    def be_empty = Matcher.new(:be_empty)
    def have_size(n) = Matcher.new(:have_size, n)
    def have_key(k) = Matcher.new(:have_key, k)
    def contain_exactly(*xs) = Matcher.new(:contain_exactly, xs)
    def match_array(xs) = Matcher.new(:contain_exactly, xs)
    def be_within(delta) = Within.new(delta)
    def be_between(lo, hi) = Matcher.new(:be_between, [lo, hi])
    def satisfy(description = "satisfy expression", &blk) = Matcher.new(:satisfy, [description, blk])
    def all(&blk) = Matcher.new(:all, blk)
    def raise_error(expected = nil) = Matcher.new(:raise_error, expected)
  end

  class Within
    def initialize(delta) = @delta = delta
    def of(x) = Matcher.new(:be_within, [@delta, x])
  end

  class BeMatcher
    def >(x) = Matcher.new(:be_gt, x)
    def >=(x) = Matcher.new(:be_ge, x)
    def <(x) = Matcher.new(:be_lt, x)
    def <=(x) = Matcher.new(:be_le, x)
  end

  Matcher = Struct.new(:kind, :arg)

  class Expectation
    def initialize(actual, block) = (@actual, @block = actual, block)
    def fail_with(m) = raise(ExpectationNotMet, m)
    def two_lines(e, g) = "expected: #{e}\n     got: #{g}"

    def to(m)
      a = @actual
      case m.kind
      when :eq then a == m.arg || fail_with(two_lines(m.arg.inspect, a.inspect) + "\n\n(compared using ==)")
      when :be then a.equal?(m.arg) || fail_with(two_lines(m.arg.inspect, a.inspect) + "\n\n(compared using equal?)")
      when :be_truthy then a || fail_with(two_lines("truthy value", a.inspect))
      when :be_falsey then !a || fail_with(two_lines("falsey value", a.inspect))
      when :be_nil then a.nil? || fail_with(two_lines("nil", a.inspect))
      when :include
        missing = m.arg.reject { |x| a.include?(x) }
        missing.empty? || fail_with("expected #{a.inspect} to include #{missing.map(&:inspect).join(", ")}")
      when :match then a.match?(m.arg) || fail_with("expected #{a.inspect} to match #{m.arg.inspect}")
      when :start_with then a.start_with?(m.arg) || fail_with("expected #{a.inspect} to start with #{m.arg.inspect}")
      when :end_with then a.end_with?(m.arg) || fail_with("expected #{a.inspect} to end with #{m.arg.inspect}")
      when :be_empty then a.empty? || fail_with("expected `#{a.inspect}.empty?` to be truthy, got false")
      when :have_size then a.size == m.arg || fail_with("expected #{a.inspect} to have size #{m.arg}, got #{a.size}")
      when :have_key then a.key?(m.arg) || fail_with("expected #{a.inspect} to have key #{m.arg.inspect}")
      when :contain_exactly
        got = a.sort_by(&:inspect)
        want = m.arg.sort_by(&:inspect)
        got == want || fail_with("expected collection contained:  #{want.inspect}\nactual collection contained:    #{got.inspect}")
      when :be_within
        delta, x = m.arg
        (a - x).abs <= delta || fail_with("expected #{a.inspect} to be within #{delta} of #{x.inspect}")
      when :be_gt then a > m.arg || fail_with("expected: > #{m.arg.inspect}\n     got:   #{a.inspect}")
      when :be_ge then a >= m.arg || fail_with("expected: >= #{m.arg.inspect}\n     got:    #{a.inspect}")
      when :be_lt then a < m.arg || fail_with("expected: < #{m.arg.inspect}\n     got:   #{a.inspect}")
      when :be_le then a <= m.arg || fail_with("expected: <= #{m.arg.inspect}\n     got:    #{a.inspect}")
      when :be_between
        lo, hi = m.arg
        (a >= lo && a <= hi) || fail_with("expected #{a.inspect} to be between #{lo.inspect} and #{hi.inspect} (inclusive)")
      when :satisfy
        description, blk = m.arg
        blk.call(a) || fail_with("expected #{a.inspect} to #{description}")
      when :all
        bad = a.reject { |x| m.arg.call(x) }
        bad.empty? || fail_with("expected #{a.inspect} to all match, but #{bad.inspect} did not")
      when :raise_error
        begin
          a.call
        rescue StandardError => err
          msg = err.message
          return msg if m.arg.nil?
          return msg if m.arg.is_a?(String) && msg == m.arg
          return msg if m.arg.is_a?(Regexp) && msg.match?(m.arg)
          fail_with("expected an error with message matching #{m.arg.inspect}, got #{msg.inspect}")
        end
        fail_with(m.arg.nil? ? "expected an exception but nothing was raised" : "expected an error with message matching #{m.arg.inspect} but nothing was raised")
      end
    end

    def not_to(m)
      a = @actual
      case m.kind
      when :eq then a != m.arg || fail_with("expected: value != #{m.arg.inspect}\n     got: #{a.inspect}\n\n(compared using ==)")
      when :be_truthy then !a || fail_with(two_lines("falsey value", a.inspect))
      when :be_nil then !a.nil? || fail_with("expected: not nil\n     got: nil")
      when :include
        present = m.arg.select { |x| a.include?(x) }
        present.empty? || fail_with("expected #{a.inspect} not to include #{present.map(&:inspect).join(", ")}")
      when :match then !a.match?(m.arg) || fail_with("expected #{a.inspect} not to match #{m.arg.inspect}")
      when :be_empty then !a.empty? || fail_with("expected `#{a.inspect}.empty?` to be falsey, got true")
      when :raise_error
        begin
          a.call
        rescue StandardError => err
          fail_with("expected no Exception, got #{err.message.inspect}")
        end
        true
      end
    end
  end

  def self.describe(description, &blk)
    g = Group.new(description, 0, description)
    LINES << "" unless GROUPS.empty?
    GROUPS << g
    LINES << description
    g.instance_eval(&blk)
    g
  end

  def self.plural(n, word) = "#{n} #{word}#{n == 1 ? "" : "s"}"

  def self.report
    LINES.each { |l| puts l }
    puts
    pending = RESULTS.select { |r| r[1] == :pending }
    failed = RESULTS.select { |r| r[1] == :failed }
    unless pending.empty?
      puts "Pending: (Failures listed here are expected and do not affect your suite's status)"
      puts
      pending.each_with_index do |r, i|
        puts "  #{i + 1}) #{r[0]}"
        puts "     # #{r[2]}"
        puts
      end
    end
    unless failed.empty?
      puts "Failures:"
      puts
      failed.each_with_index do |r, i|
        puts "  #{i + 1}) #{r[0]}"
        body = r[2].split("\n", -1).map { |l| l == "" ? "" : "       " + l }.join("\n").sub(/\A\s+/, "")
        puts "     Failure/Error: " + body
        puts
      end
    end
    summary = "#{plural(RESULTS.size, "example")}, #{plural(failed.size, "failure")}"
    summary += ", #{pending.size} pending" unless pending.empty?
    puts summary
    failed.empty?
  end

  def self.run
    ok = report
    exit(1) unless ok
    ok
  end
end

def describe(description, &blk) = RSpecRef.describe(description, &blk)
