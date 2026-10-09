# Reference implementation of the money gem's core in plain Ruby, for test/sakelib/money.rb (the gem is not
# installed). Money.new(fractional, currency), from_amount, arithmetic, Comparable, allocate/split, format with
# the gem's per-currency defaults, Money::Currency, Money::Bank::VariableExchange. Amounts are exact: Floats are
# read with Float#rationalize (as the gem's BigDecimal reads them) and rounded half to even, the gem's default.

class Money
  include Comparable

  class Currency
    class UnknownCurrency < ArgumentError; end
    include Comparable
    attr_reader :iso_code, :name, :symbol, :subunit_to_unit, :decimal_mark, :thousands_separator, :symbol_first, :priority

    def initialize(iso_code, name, symbol, subunit_to_unit, decimal_mark, thousands_separator, symbol_first, priority)
      @iso_code, @name, @symbol, @subunit_to_unit = iso_code, name, symbol, subunit_to_unit
      @decimal_mark, @thousands_separator, @symbol_first, @priority = decimal_mark, thousands_separator, symbol_first, priority
    end

    TABLE = [
      ["USD", "United States Dollar", "$", 100, ".", ",", true, 1],
      ["EUR", "Euro", "€", 100, ",", ".", true, 2],
      ["GBP", "British Pound", "£", 100, ".", ",", true, 3],
      ["AUD", "Australian Dollar", "$", 100, ".", ",", true, 4],
      ["CAD", "Canadian Dollar", "$", 100, ".", ",", true, 5],
      ["JPY", "Japanese Yen", "¥", 1, ".", ",", true, 6],
      ["CHF", "Swiss Franc", "CHF", 100, ".", ",", true, 100],
      ["CNY", "Chinese Renminbi Yuan", "¥", 100, ".", ",", true, 100],
      ["INR", "Indian Rupee", "₹", 100, ".", ",", true, 100],
      ["KRW", "South Korean Won", "₩", 1, ".", ",", true, 100]
    ].to_h { |row| [row[0], new(*row)] }

    def self.find(id) = TABLE[id.to_s.upcase]

    def self.wrap(x)
      case x
      when Currency then x
      when String, Symbol
        find(x) or raise UnknownCurrency, "Unknown currency '#{x.to_s.downcase}'"
      end
    end

    def self.all = TABLE.values.sort
    def id = iso_code.downcase.to_sym
    def code = symbol
    def decimal_places = subunit_to_unit == 1 ? 0 : subunit_to_unit.to_s.length - 1
    def symbol_first? = symbol_first
    def <=>(other) = [priority, iso_code] <=> [other.priority, other.iso_code]
    def to_s = iso_code
    def to_str = iso_code
    def inspect = "#<Money::Currency id: #{iso_code.downcase}, priority: #{priority}, symbol_first: #{symbol_first}, thousands_separator: #{thousands_separator}, decimal_mark: #{decimal_mark}, iso_code: #{iso_code}, name: #{name}, symbol: #{symbol}, subunit_to_unit: #{subunit_to_unit}>"
  end

  module Bank
    class UnknownRate < StandardError; end

    class VariableExchange
      attr_reader :rates

      def initialize = @rates = {}
      def rate_key(from, to) = "#{Currency.wrap(from).iso_code}_TO_#{Currency.wrap(to).iso_code}"

      def add_rate(from, to, rate)
        raise ArgumentError, "rate must be numeric" unless rate.is_a?(Numeric)
        @rates[rate_key(from, to)] = rate
      end

      alias set_rate add_rate
      def get_rate(from, to) = @rates[rate_key(from, to)]

      def exchange_with(from, to_currency)
        to = Currency.wrap(to_currency)
        return from if from.currency == to
        rate = get_rate(from.currency, to)
        raise UnknownRate, "No conversion rate known for '#{from.currency}' -> '#{to}'" unless rate
        Money.from_amount(from.to_d * Money.to_r(rate), to)
      end
    end
  end

  attr_reader :fractional, :currency

  def self.default_currency = "USD"
  def self.default_bank = (@default_bank ||= Bank::VariableExchange.new)

  def self.to_r(x)
    case x
    when Float then x.rationalize
    when Integer then x.to_r
    when Rational then x
    end
  end

  def self.round_half_even(r)
    fl = r.floor
    frac = r - fl
    return fl if frac < Rational(1, 2)
    return fl + 1 if frac > Rational(1, 2)
    fl.even? ? fl : fl + 1
  end

  def initialize(fractional, currency = nil)
    raise ArgumentError, "fractional must be numeric" unless fractional.is_a?(Numeric)
    @fractional = Money.round_half_even(Money.to_r(fractional))
    @currency = Currency.wrap(currency.nil? ? Money.default_currency : currency)
  end

  def self.from_amount(amount, currency = nil)
    raise ArgumentError, "'amount' must be numeric" unless amount.is_a?(Numeric)
    cur = Currency.wrap(currency.nil? ? default_currency : currency)
    new(to_r(amount) * cur.subunit_to_unit, cur)
  end

  def self.from_cents(cents, currency = nil) = new(cents, currency)
  def self.zero(currency = nil) = new(0, currency)
  def self.us_dollar(cents) = new(cents, "USD")
  def self.euro(cents) = new(cents, "EUR")
  def self.pound_sterling(cents) = new(cents, "GBP")
  def self.add_rate(from, to, rate) = default_bank.add_rate(from, to, rate)

  def cents = fractional
  def to_d = Rational(fractional, currency.subunit_to_unit)
  def amount = to_d.to_f
  def to_f = amount
  def to_i = to_d.to_i
  def currency_as_string = currency.iso_code
  def zero? = fractional == 0
  def positive? = fractional > 0
  def negative? = fractional < 0
  def nonzero? = fractional == 0 ? nil : self
  def abs = Money.new(fractional.abs, currency)
  def -@ = Money.new(-fractional, currency)
  def +@ = self

  def same_currency(other)
    raise TypeError, "#{other.class} can't be coerced into Money" unless other.is_a?(Money)
    other.currency == currency ? other : other.exchange_to(currency)
  end

  def +(other) = Money.new(fractional + same_currency(other).fractional, currency)
  def -(other) = Money.new(fractional - same_currency(other).fractional, currency)

  def *(value)
    raise TypeError, "Can't multiply a Money by a Money" if value.is_a?(Money)
    raise TypeError, "Can't multiply a Money by #{value.class}" unless value.is_a?(Numeric)
    Money.new(fractional.to_r * Money.to_r(value), currency)
  end

  def /(value)
    if value.is_a?(Money)
      other = same_currency(value)
      raise ZeroDivisionError, "divided by 0" if other.fractional == 0
      return Rational(fractional, other.fractional).to_f
    end
    raise TypeError, "Can't divide a Money by #{value.class}" unless value.is_a?(Numeric)
    raise ZeroDivisionError, "divided by 0" if value == 0
    Money.new(fractional.to_r / Money.to_r(value), currency)
  end

  alias div /

  def <=>(other)
    return nil unless other.is_a?(Money)
    return 0 if zero? && other.zero?
    if other.currency != currency
      begin
        other = other.exchange_to(currency)
      rescue Bank::UnknownRate
        return nil
      end
    end
    fractional <=> other.fractional
  end

  def eql?(other) = other.is_a?(Money) && self == other

  def allocate(parts)
    ps = case parts
         when Integer then Array.new(parts, 1)
         when Array then parts.all?(&:zero?) ? Array.new(parts.size, 1) : parts.dup
         end
    raise ArgumentError, "need at least one party" if ps.empty?
    result = []
    remaining = fractional
    until ps.empty?
      sum = ps.sum
      part = ps.pop
      split = 0
      split = (remaining * part / sum).truncate if sum > 0
      result.unshift(split)
      remaining -= split
    end
    result.map { |c| Money.new(c, currency) }
  end

  def split(n) = allocate(n)
  def exchange_to(other_currency, bank = nil) = (bank || Money.default_bank).exchange_with(self, other_currency)

  def format(symbol: true, no_cents: false, no_cents_if_whole: false, with_currency: false, thousands_separator: nil, decimal_mark: nil, sign_before_symbol: true, symbol_position: nil, format: nil)
    cur = currency
    whole, sub = fractional.abs.divmod(cur.subunit_to_unit)
    sep = thousands_separator.nil? ? cur.thousands_separator : thousands_separator
    mark = decimal_mark.nil? ? cur.decimal_mark : decimal_mark
    number = whole.to_s.gsub(/(\d)(?=(\d{3})+\z)/, "\\1#{sep}")
    places = cur.decimal_places
    unless no_cents || places == 0 || (no_cents_if_whole && sub == 0)
      number = "#{number}#{mark}#{sub.to_s.rjust(places, "0")}"
    end
    sym = case symbol
          when true then cur.symbol
          when false, nil then ""
          when String then symbol
          end
    sign = fractional < 0 ? "-" : ""
    number = "#{sign}#{number}" unless sign_before_symbol
    text = if format
             format.gsub("%u", sym).gsub("%n", number)
           elsif sym == ""
             number
           elsif symbol_position == :after || (symbol_position.nil? && !cur.symbol_first)
             "#{number} #{sym}"
           else
             "#{sym}#{number}"
           end
    text = "#{sign}#{text}" if sign_before_symbol
    text = "#{text} #{cur.iso_code}" if with_currency
    text
  end

  def to_s = format(symbol: false, thousands_separator: "", no_cents_if_whole: currency.decimal_places == 0)
  def inspect = "#<Money fractional:#{fractional} currency:#{currency.iso_code}>"
end
