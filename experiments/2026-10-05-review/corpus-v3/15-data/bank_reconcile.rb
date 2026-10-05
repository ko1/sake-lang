class Entry
  attr_reader :source, :day, :amount, :memo
  attr_accessor :matched

  def initialize(source, day, amount, memo, matched)
    @source = source
    @day = day
    @amount = amount
    @memo = memo
    @matched = matched
  end
end

class ParseError < StandardError
  attr_reader :source, :text

  def initialize(message, source, text)
    super(message)
    @source = source
    @text = text
  end
end

def bank_csv
  <<~CSV
    2026-05-01;-1250,00;RENT MAY
    2026-05-02;-42,17;GROCERY MART 0112
    2026-05-03;3200,00;PAYROLL ACME
    2026-05-05;-89,99;ISP MONTHLY
    2026-05-07;-15,00;ATM FEE
    2026-05-09;-42,17;GROCERY MART 0112
    2026-05-11;-230,40;HARDWARE CO
    2026-05-12;n/a;PENDING
    2026-05-14;-60,00;TRANSFER TO SAVINGS
  CSV
end

def ledger_csv
  <<~CSV
    2026-04-30,-1250.00,Rent
    2026-05-02,-42.17,Groceries
    2026-05-03,3200.00,Salary
    2026-05-04,-89.99,Internet
    2026-05-09,-42.17,Groceries
    2026-05-10,-23.04,Hardware store
    2026-05-13,-60.00,Savings
    2026-05-20,-75.00,Gym
  CSV
end

def day_number(date)
  m = date.match(/\A(\d{4})-(\d\d)-(\d\d)\z/)
  raise ParseError.new("bad date", "date", date) if m.nil?
  t = Time.new(m[1].to_i, m[2].to_i, m[3].to_i)
  ((t - epoch) / 86400).round
end

def cents(text, decimal_mark)
  normalized = text.tr(decimal_mark, ".")
  raise ParseError.new("bad amount", "amount", text) unless normalized.match?(/\A-?\d+\.\d\d\z/)
  (normalized.to_f * 100).round
end

def load(text, source, sep, decimal_mark, problems)
  entries = []
  text.each_line do |line|
    parts = line.chomp.split(sep)
    begin
      raise ParseError.new("expected 3 fields", source, line) if parts.size != 3
      date, amount, memo = parts
      entries << Entry.new(source, day_number(date), cents(amount, decimal_mark), memo, nil)
    rescue ParseError => e
      problems << "#{source}: #{e.message} (#{e.text})"
    end
  end
  entries
end

def money(c) = format("%s%d.%02d", c < 0 ? "-" : " ", c.abs / 100, c.abs % 100)

def epoch = Time.new(2026, 1, 1)

def date_of(day) = (epoch + (day * 86400 + 43200)).strftime("%m-%d")

problems = []
bank = load(bank_csv, "bank", ";", ",", problems)
ledger = load(ledger_csv, "ledger", ",", ".", problems)

pairs = []
0.upto(3) do |tolerance|
  ledger.each do |l|
    next if l.matched
    candidate = bank.find do |b|
      b.matched.nil? && b.amount == l.amount && (b.day - l.day).abs <= tolerance
    end
    next unless candidate
    l.matched = candidate
    candidate.matched = l
    pairs << [l, candidate, tolerance]
  end
end

puts "Matched #{pairs.size} transactions:"
pairs.sort_by { |l, b, t| l.day }.each do |l, b, t|
  lag = t == 0 ? "" : " (#{b.day - l.day}d)"
  puts format("  %s %10s  %-15s <-> %s%s", date_of(l.day), money(l.amount), l.memo, b.memo, lag)
end

only_ledger = ledger.select { |e| e.matched.nil? }
only_bank = bank.select { |e| e.matched.nil? }
puts
puts "In ledger only:"
only_ledger.each { |e| puts format("  %s %10s  %s", date_of(e.day), money(e.amount), e.memo) }
puts "In bank only:"
only_bank.each do |e|
  hint = only_ledger.find { |l| l.amount * 10 == e.amount || l.amount == e.amount * 10 }
  extra = hint ? "  -- digit slip? ledger has #{money(hint.amount)} #{hint.memo}" : ""
  puts format("  %s %10s  %s%s", date_of(e.day), money(e.amount), e.memo, extra)
end
puts
puts "Unreadable lines:"
problems.each { |pr| puts "  #{pr}" }
diff = bank.sum(&:amount) - ledger.sum(&:amount)
puts
puts "Balance difference (bank - ledger): #{money(diff).strip}"
