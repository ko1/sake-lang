# Reconcile a bank statement against the internal ledger; classify each discrepancy and fail loudly on bad data.
class CorruptRecord < StandardError
  attr_reader :source, :index

  def initialize(message, source, index)
    super(message)
    @source = source
    @index = index
  end
end

class DuplicateRef < StandardError
  attr_reader :ref

  def initialize(message, ref)
    super(message)
    @ref = ref
  end
end

class Txn
  attr_reader :ref, :date, :cents, :memo

  def initialize(ref, date, cents, memo)
    @ref = ref
    @date = date
    @cents = cents
    @memo = memo
  end
end

def parse_amount(s)
  m = s.match(/\A(-?)(\d+)\.(\d\d)\z/) or return nil
  cents = m[2].to_i * 100 + m[3].to_i
  m[1] == "-" ? -cents : cents
end

def load_txns(source, rows)
  by_ref = {}
  rows.each_with_index do |row, i|
    fields = row.split("|")
    raise CorruptRecord.new("#{source} row #{i}: expected 4 fields", source, i) if fields.size != 4
    ref, date, amount, memo = fields
    cents = parse_amount(amount)
    raise CorruptRecord.new("#{source} row #{i}: bad amount #{amount}", source, i) if !cents    
    raise DuplicateRef.new("#{source}: duplicate ref #{ref}", ref) if by_ref.key?(ref)
    by_ref[ref] = Txn.new(ref, date, cents, memo)
  end
  by_ref
end

def money(cents)
  sign = cents < 0 ? "-" : ""
  a = cents.abs
  "#{sign}#{a / 100}.#{(a % 100).to_s.rjust(2, "0")}"
end

def reconcile(ledger, bank)
  issues = []
  ledger.each do |ref, l|
    b = bank[ref]
    if !b    
      issues << [:missing_in_bank, ref, "#{money(l.cents)} #{l.memo}"]
      next
    end
    diff = b.cents - l.cents
    if diff != 0
      issues << [:amount_mismatch, ref, "ledger #{money(l.cents)}, bank #{money(b.cents)} (#{money(diff)})"]
    elsif b.date != l.date
      issues << [:date_mismatch, ref, "#{l.date} vs #{b.date}"]
    end
  end
  bank.each do |ref, b|
    issues << [:missing_in_ledger, ref, "#{money(b.cents)} #{b.memo}"] unless ledger.key?(ref)
  end
  issues
end

def run(name, ledger_rows, bank_rows)
  puts "== #{name}"
  ledger = load_txns("ledger", ledger_rows)
  bank = load_txns("bank", bank_rows)
  issues = reconcile(ledger, bank)
  if issues.empty?
    puts "balanced: #{ledger.size} transactions"
    return
  end
  issues.group_by(&:first).each do |kind, list|
    puts "#{kind} (#{list.size})"
    list.each { |_, ref, detail| puts "  #{ref}: #{detail}" }
  end
  net = bank.values.sum(&:cents) - ledger.values.sum(&:cents)
  puts "net difference #{money(net)}"
rescue CorruptRecord => e
  puts "cannot reconcile: #{e.message} (fix #{e.source} first)"
rescue DuplicateRef => e
  puts "cannot reconcile: #{e.message}"
end

ledger = [
  "R1|2026-09-01|1200.00|invoice 17", "R2|2026-09-02|-45.10|stationery", "R3|2026-09-03|-300.00|rent share",
  "R4|2026-09-05|89.99|refund", "R5|2026-09-07|-12.00|bank fee", "R6|2026-09-08|560.40|invoice 18"
]
bank = [
  "R1|2026-09-01|1200.00|INV17", "R2|2026-09-02|-45.01|STATIONERY", "R3|2026-09-04|-300.00|RENT",
  "R4|2026-09-05|89.99|REFUND", "R6|2026-09-08|560.40|INV18", "R7|2026-09-09|-0.50|INTEREST ADJ"
]
run("september", ledger, bank)
run("clean", ["A|2026-10-01|10.00|x", "B|2026-10-01|-2.50|y"], ["B|2026-10-01|-2.50|Y", "A|2026-10-01|10.00|X"])
run("corrupt", ledger, ["R1|2026-09-01|1200.00|INV17", "R2|2026-09-02|-45,10|STATIONERY"])
run("short", ["R1|2026-09-01|1.00"], bank)
run("dup", ledger, ["R1|2026-09-01|1.00|a", "R1|2026-09-01|1.00|b"])
