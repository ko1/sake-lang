# Reference implementation of the chronic subset in plain Ruby, for test/sakelib/chronic.rb (the gem is not
# installed). Same algorithm as sakelib/chronic.sake: normalize, tokenize and tag, pick a span by the kinds of
# the tokens, guess its middle. The values follow the gem's test suite (now = 2006-08-16 14:00).

class ChronicToken
  attr_reader :word
  attr_accessor :kind, :num, :sym, :parts

  def initialize(word, kind: nil, num: nil, sym: nil, parts: nil)
    @word, @kind, @num, @sym, @parts = word, kind, num, sym, parts || []
  end
end

class ChronicSpan
  attr_reader :from, :to

  def initialize(from, to)
    @from, @to = from, to
  end

  def width = (@to - @from).to_i
  def to_s = "#{@from}..#{@to}"
end

module Chronic
  module_function

  def parse(text, now: Time.now, context: :future, ambiguous_time_range: 6)
    span = parse_span(text, now: now, context: context, ambiguous_time_range: ambiguous_time_range)
    span.nil? ? nil : guess(span)
  end

  def parse_span(text, now: Time.now, context: :future, ambiguous_time_range: 6)
    tokens = tokenize(pre_normalize(text))
    return nil if tokens.nil? || tokens.empty?
    handle(tokens, now, context, ambiguous_time_range)
  end

  def guess(span)
    w = span.width
    w > 1 ? span.from + w / 2 : span.from
  end

  def pre_normalize(text)
    s = text.strip.downcase
    s = s.gsub(/\b(\d+)(?:st|nd|rd|th)\b/, "\\1")
    s = s.gsub(/\btoday\b/, "this day")
    s = s.gsub(/\btomm?orr?ow\b/, "next day")
    s = s.gsub(/\byesterday\b/, "last day")
    s = s.gsub(/\bnoon\b/, "12:00 pm")
    s = s.gsub(/\bmidnight\b/, "24:00")
    s = s.gsub(/\bnow\b/, "this second")
    s = s.gsub(/\b(?:ago|before)\b/, "past")
    s = s.gsub(/\bthis (?:last|past)\b/, "last")
    s = s.gsub(/\b(?:in the|during the|at) (morning|afternoon|evening|night)\b/, "\\1")
    s = s.gsub(/\btonight\b/, "this night")
    s = s.gsub(/\b(\d{1,2})\s*([ap])\.?m?\.?\b/, "\\1 \\2m")
    s = s.gsub(/\b(hence|after|from)\b/, "future")
    s = s.gsub(/\A\s?an? /, "1 ")
    s
  end

  def tokenize(text)
    tokens = []
    words = text.scan(/\d{4}-\d{1,2}-\d{1,2}|\d{1,2}\/\d{1,2}(?:\/\d{2,4})?|\d{1,2}(?:[.:]\d{2}){1,2}|\d+|[a-z]+/)
    words.each do |w|
      t = tag(w)
      return nil if t.nil?
      tokens << t if t.kind != :noise
    end
    tokens
  end

  MONTHS = { "jan" => 1, "feb" => 2, "mar" => 3, "apr" => 4, "may" => 5, "jun" => 6, "jul" => 7, "aug" => 8, "sep" => 9, "oct" => 10, "nov" => 11, "dec" => 12 }
  DAYNAMES = { "sun" => 0, "mon" => 1, "tue" => 2, "wed" => 3, "thu" => 4, "fri" => 5, "sat" => 6 }
  UNITS = { "second" => :second, "seconds" => :second, "sec" => :second, "secs" => :second,
            "minute" => :minute, "minutes" => :minute, "min" => :minute, "mins" => :minute,
            "hour" => :hour, "hours" => :hour, "hr" => :hour, "hrs" => :hour,
            "day" => :day, "days" => :day, "week" => :week, "weeks" => :week, "wk" => :week, "wks" => :week,
            "fortnight" => :fortnight, "fortnights" => :fortnight,
            "month" => :month, "months" => :month, "mo" => :month, "year" => :year, "years" => :year, "yr" => :year, "yrs" => :year }

  def tag(w)
    t = ChronicToken.new(w)
    if w.match?(/\A\d{4}-\d{1,2}-\d{1,2}\z/)
      y, m, d = w.split("-").map(&:to_i)
      set_token(t, :date, [y || 0, m || 0, d || 0])
    elsif w.match?(/\A\d{1,2}\/\d{1,2}(\/\d{2,4})?\z/)
      m, d, y = w.split("/").map(&:to_i)
      y = y.nil? ? 0 : y < 100 ? (y <= 68 ? 2000 + y : 1900 + y) : y
      set_token(t, :date, [y, m || 0, d || 0])
    elsif w.match?(/\A\d{1,2}([.:]\d{2}){1,2}\z/)
      h, mi, s = w.split(/[.:]/).map(&:to_i)
      set_token(t, :time, [h || 0, mi || 0, s || 0])
    elsif w.match?(/\A\d+\z/)
      t.kind = :scalar
      t.num = w.to_i
    elsif w.match?(/\A(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\z/) && month_word?(w)
      t.kind = :month
      t.num = MONTHS[w[0, 3]] || 0
    elsif w.match?(/\A(sun|mon|tue|wed|thu|fri|sat)[a-z]*\z/) && day_word?(w)
      t.kind = :dayname
      t.num = DAYNAMES[w[0, 3]] || 0
    elsif w == "this" || w == "next" || w == "last"
      set_sym(t, :grabber, w.to_sym)
    elsif UNITS.key?(w)
      set_sym(t, :unit, UNITS[w])
    elsif w == "past"
      set_sym(t, :pointer, :past)
    elsif w == "future" || w == "in"
      set_sym(t, :pointer, :future)
    elsif w == "am" || w == "pm"
      set_sym(t, :meridian, w.to_sym)
    elsif %w[morning afternoon evening night].include?(w)
      set_sym(t, :portion, w.to_sym)
    elsif %w[at on the of and].include?(w)
      t.kind = :noise
    else
      return nil
    end
    t
  end

  def month_word?(w) = w.match?(/\A(jan(uary)?|feb(ruary)?|mar(ch)?|apr(il)?|may|june?|july?|aug(ust)?|sept?(ember)?|oct(ober)?|nov(ember)?|dec(ember)?)\z/)
  def day_word?(w) = w.match?(/\A(sun(day)?|mon(day)?|tue(s|sday)?|wed(nesday)?|thu(r|rs|rsday)?|fri(day)?|sat(urday)?)\z/)

  def set_token(t, kind, parts)
    t.kind = kind
    t.parts = parts
  end

  def set_sym(t, kind, sym)
    t.kind = kind
    t.sym = sym
  end

  def kinds(tokens) = tokens.map(&:kind)
  def num(t) = t.num || 0
  def sym(t) = t.sym || :none

  def handle(tokens, now, context, atr)
    ks = kinds(tokens)
    if ks[0] == :scalar && ks[1] == :unit && ks[2] == :pointer
      return offset_from(tokens, num(tokens[0]), sym(tokens[1]), sym(tokens[2]), now, context, atr)
    elsif ks[0] == :pointer && ks[1] == :scalar && ks[2] == :unit
      return offset_from(tokens, num(tokens[1]), sym(tokens[2]), sym(tokens[0]), now, context, atr)
    end
    mi = ks.index(:month)
    tokens.each_with_index do |t, i|
      next unless t.kind == :scalar
      year = num(t) > 31 || t.word.size == 4
      date_part = !mi.nil? && (i == mi - 1 || i == mi + 1 || (i == mi + 2 && ks[mi + 1] == :scalar && year))
      next if date_part
      return nil if num(t) > 24
      set_token(t, :time, [num(t), 0, 0])
    end
    return nil if tokens.count { |t| t.kind == :time } > 1
    time = tokens.find { |t| t.kind == :time }
    meridian = tokens.find { |t| t.kind == :meridian }
    portion = tokens.find { |t| t.kind == :portion }
    day = tokens.reject { |t| t.kind == :time || t.kind == :meridian }
    if !time.nil? && !portion.nil? && meridian.nil?
      meridian = ChronicToken.new("", kind: :meridian, sym: sym(portion) == :morning ? :am : :pm)
      without = day.reject { |t| t.kind == :portion }
      day = without unless kinds(without) == [:grabber]
    end
    span = day_span(day, now, context)
    return span if time.nil?
    return nil if span.nil? && !day.empty?
    t = resolve_time(span.nil? ? now : span.from, time, meridian, atr, span.nil?)
    ChronicSpan.new(t, t + 1)
  end

  def day_span(day, now, context)
    ks = kinds(day)
    n = day.size
    return nil if n == 0
    a = day[0]
    b = n > 1 ? day[1] : a
    c = n > 2 ? day[2] : a
    if n == 2 && ks == [:grabber, :unit]
      grabber_unit(sym(a), sym(b), now, context)
    elsif n == 2 && ks == [:grabber, :dayname]
      dayname_span(sym(a), num(b), now, context)
    elsif n == 2 && ks == [:grabber, :month]
      month_span(sym(a), num(b), now)
    elsif n == 2 && ks == [:grabber, :portion]
      portion_span(sym(a), sym(b), now)
    elsif n == 1 && ks[0] == :dayname
      dayname_span(:this, num(a), now, context)
    elsif n == 1 && ks[0] == :month
      month_span(:this, num(a), now)
    elsif n == 1 && ks[0] == :portion
      portion_span(:this, sym(a), now)
    elsif n == 2 && ks == [:month, :scalar]
      month_day(now, 0, num(a), num(b), context)
    elsif n == 2 && ks == [:scalar, :month]
      month_day(now, 0, num(b), num(a), context)
    elsif n == 3 && ks == [:month, :scalar, :scalar]
      month_day(now, num(c), num(a), num(b), context)
    elsif n == 3 && ks == [:scalar, :month, :scalar]
      month_day(now, num(c), num(b), num(a), context)
    elsif n == 1 && ks[0] == :date
      y, m, d = a.parts
      month_day(now, y || 0, m || 0, d || 0, context)
    end
  end

  def offset_from(tokens, n, unit, dir, now, context, atr)
    rest = tokens.drop(3)
    anchor = now
    unless rest.empty?
      span = handle(rest, now, context, atr)
      return nil if span.nil?
      anchor = guess(span)
    end
    t = offset(anchor, unit, dir == :past ? -n : n)
    ChronicSpan.new(t, t + 1)
  end

  def offset(t, unit, n)
    case unit
    when :second then t + n
    when :minute then t + n * 60
    when :hour then t + n * 3600
    when :day then t + n * 86400
    when :week then t + n * 604800
    when :fortnight then t + n * 1209600
    when :month then add_months(t, n)
    when :year then add_months(t, n * 12)
    else t
    end
  end

  def add_months(t, n)
    y = t.year + (t.month - 1 + n) / 12
    m = (t.month - 1 + n) % 12 + 1
    d = t.day.clamp(1, days_in_month(y, m))
    mk(t, y, m, d, t.hour, t.min, t.sec)
  end

  def resolve_time(base, time, meridian, atr, relative)
    h, m, s = time.parts
    h ||= 0
    m ||= 0
    s ||= 0
    day0 = midnight(base)
    if !meridian.nil?
      return day0 + (h % 12 + (sym(meridian) == :pm ? 12 : 0)) * 3600 + m * 60 + s
    end
    if h >= 1 && h <= 12 && atr != :none
      tick = (h % 12) * 3600 + m * 60 + s
      lower = day0 + (atr.is_a?(Integer) ? atr : 6) * 3600
      cands = [day0 + tick, day0 + tick + 43200, day0 + 86400 + tick]
    elsif h >= 1 && h <= 12
      tick = (h % 12) * 3600 + m * 60 + s
      lower = relative ? base : day0
      cands = [day0 + tick, day0 + tick + 43200, day0 + 86400 + tick]
    else
      tick = h * 3600 + m * 60 + s
      lower = relative ? base : day0
      cands = [day0 + tick, day0 + 86400 + tick]
    end
    cands.find { |c| c >= lower } || cands.fetch(-1)
  end

  def grabber_unit(g, unit, now, context)
    case unit
    when :second
      g == :next ? span_of(now + 1, 1) : g == :last ? span_of(now - 1, 1) : span_of(now, 1)
    when :minute
      start = floor_to(now, 60)
      g == :next ? span_of(start + 60, 60) : g == :last ? span_of(start - 60, 60) : ChronicSpan.new(now, start + 60)
    when :hour
      start = floor_to(now, 3600)
      g == :next ? span_of(start + 3600, 3600) : g == :last ? span_of(start - 3600, 3600) : ChronicSpan.new(now, start + 3600)
    when :day
      today = midnight(now)
      if g == :next then span_of(today + 86400, 86400)
      elsif g == :last then span_of(today - 86400, 86400)
      elsif context == :past then ChronicSpan.new(today, floor_to(now, 3600))
      else ChronicSpan.new(floor_to(now, 3600), today + 86400)
      end
    when :week
      start = midnight(now) - now.wday * 86400
      if g == :next then span_of(start + 604800, 604800)
      elsif g == :last then span_of(start - 604800, 604800)
      elsif context == :past then ChronicSpan.new(start, floor_to(now, 3600))
      else ChronicSpan.new(floor_to(now, 3600) + 3600, start + 604800)
      end
    when :fortnight
      start = midnight(now) - now.wday * 86400
      if g == :next then span_of(start + 604800, 1209600)
      elsif g == :last then span_of(start - 1209600, 1209600)
      else ChronicSpan.new(floor_to(now, 3600) + 3600, start + 1209600)
      end
    when :month
      ms = mk(now, now.year, now.month, 1)
      if g == :next then ChronicSpan.new(add_months(ms, 1), add_months(ms, 2))
      elsif g == :last then ChronicSpan.new(add_months(ms, -1), ms)
      elsif context == :past then ChronicSpan.new(ms, midnight(now))
      else ChronicSpan.new(midnight(now) + 86400, add_months(ms, 1))
      end
    when :year
      ys = mk(now, now.year, 1, 1)
      if g == :next then ChronicSpan.new(add_months(ys, 12), add_months(ys, 24))
      elsif g == :last then ChronicSpan.new(add_months(ys, -12), ys)
      elsif context == :past then ChronicSpan.new(ys, midnight(now))
      else ChronicSpan.new(midnight(now) + 86400, add_months(ys, 12))
      end
    end
  end

  def dayname_span(g, wd, now, context)
    g = :last if g == :this && context == :past
    d = midnight(now)
    step = g == :last ? -86400 : 86400
    d += step
    d += step while d.wday != wd
    span_of(d, 86400)
  end

  def month_span(g, m, now)
    y = now.year
    cur = now.month
    y += 1 if g == :this && cur > m
    y += 1 if g == :next && cur >= m
    y -= 1 if g == :last && cur < m
    start = mk(now, y, m, 1)
    ChronicSpan.new(start, add_months(start, 1))
  end

  def portion_span(g, portion, now)
    lo, hi = case portion
             when :morning then [6, 12]
             when :afternoon then [13, 17]
             when :evening then [17, 20]
             else [20, 24]
             end
    today = midnight(now)
    start = today + lo * 3600
    start += 86400 if g == :next && start <= now
    start -= 86400 if g == :last && start + (hi - lo) * 3600 > now
    span_of(start, (hi - lo) * 3600)
  end

  def month_day(now, y, m, d, context)
    return nil if m < 1 || m > 12 || d < 1
    year = y == 0 ? now.year : y
    return nil if d > days_in_month(year, m)
    start = mk(now, year, m, d)
    if y == 0 && context == :future && start + 86400 <= now
      year += 1
      return nil if d > days_in_month(year, m)
      start = mk(now, year, m, d)
    end
    span_of(start, 86400)
  end

  def mk(now, y, m, d, h = 0, mi = 0, s = 0) = Time.new(y, m, d, h, mi, s, now.utc_offset)
  def midnight(t) = mk(t, t.year, t.month, t.day)
  def floor_to(t, secs) = t - (t.hour * 3600 + t.min * 60 + t.sec) % secs
  def span_of(start, secs) = ChronicSpan.new(start, start + secs)

  def days_in_month(y, m)
    return 29 if m == 2 && ((y % 4 == 0 && y % 100 != 0) || y % 400 == 0)
    [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31].fetch(m - 1)
  end
end
