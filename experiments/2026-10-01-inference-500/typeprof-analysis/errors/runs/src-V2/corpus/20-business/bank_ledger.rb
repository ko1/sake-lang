class Account
  attr_reader :code, :name, :kind
  attr_accessor :debits, :credits

  def initialize(code, name, kind, debits, credits)
    @code = code
    @name = name
    @kind = kind
    @debits = debits
    @credits = credits
  end

  def debit_normal? = kind == :asset || kind == :expense
  def balance = debit_normal? ? debits - credits : credits - debits
end

class Journal
  attr_reader :no, :date, :memo, :lines

  def initialize(no, date, memo, lines)
    @no = no
    @date = date
    @memo = memo
    @lines = lines
  end
end

class LedgerError < StandardError
  attr_reader :entry_no

  def initialize(message, entry_no)
    super(message)
    @entry_no = entry_no
  end
end

CHART = [
  ["1000", "Cash", :asset], ["1100", "Accounts receivable", :asset], ["1500", "Equipment", :asset],
  ["2000", "Accounts payable", :liability], ["2100", "Loan", :liability],
  ["3000", "Owner equity", :equity], ["4000", "Sales", :income], ["4100", "Interest income", :income],
  ["5000", "Rent", :expense], ["5100", "Wages", :expense], ["5200", "Supplies", :expense], ["5300", "Interest expense", :expense]
]

def amount(s)
  whole, frac = s.split(".")
  whole.to_i * 100 + (frac || "").ljust(2, "0").to_i
end

def show(c)
  sign = c < 0 ? "-" : ""
  c = c.abs
  "#{sign}#{c / 100}.#{(c % 100).to_s.rjust(2, "0")}"
end

def post(accounts, journal)
  no = journal.no
  lines = journal.lines
  raise LedgerError.new("needs at least two lines", no) if lines.size < 2
  lines.each do |code, _side, cents|
    raise LedgerError.new("unknown account #{code}", no) unless accounts.key?(code)
    raise LedgerError.new("non-positive amount on #{code}", no) if cents <= 0
  end
  dr = lines.select { |_c, side, _cents| side == :dr }.sum { |_c, _side, cents| cents }
  cr = lines.select { |_c, side, _cents| side == :cr }.sum { |_c, _side, cents| cents }
  raise LedgerError.new("unbalanced: debits #{show(dr)} credits #{show(cr)}", no) if dr != cr
  lines.each do |code, side, cents|
    acct = accounts.fetch(code)
    if side == :dr
      acct.debits += cents
    else
      acct.credits += cents
    end
  end
  dr
end

def parse_journal(text)
  journals = []
  text.lines.each do |raw|
    line = raw.rstrip
    next if line.empty?
    if line.start_with?(" ")
      m = line.match(/\A\s+(\d{4})\s+(dr|cr)\s+([\d.]+)\z/)
      raise LedgerError.new("cannot read '#{line.strip}'", journals.last.no) unless m
      journals.last.lines << [m[1], m[2].to_sym, amount(m[3])]
    else
      date, memo = line.split(" ", 2)
      journals << Journal.new(journals.size + 1, date, memo, [])
    end
  end
  journals
end

accounts = {}
CHART.each { |code, name, kind| accounts[code] = Account.new(code, name, kind, 0, 0) }

text = <<~TXT
  2026-09-01 Owner investment
    1000 dr 25000
    3000 cr 25000
  2026-09-01 Loan from bank
    1000 dr 10000
    2100 cr 10000
  2026-09-02 Buy equipment
    1500 dr 8400.50
    1000 cr 4000
    2000 cr 4400.50
  2026-09-05 Rent September
    5000 dr 1800
    1000 cr 1800
  2026-09-10 Invoice client A
    1100 dr 6200
    4000 cr 6200
  2026-09-12 Typo in supplies
    5200 dr 120.40
    1000 cr 120.04
  2026-09-15 Cash sale
    1000 dr 950.25
    4000 cr 950.25
  2026-09-20 Client A pays
    1000 dr 4000
    1100 cr 4000
  2026-09-25 Payroll
    5100 dr 5200
    1000 cr 5200
  2026-09-28 Coffee machine
    5900 dr 300
    1000 cr 300
  2026-09-30 Loan interest
    5300 dr 62.50
    1000 cr 62.50
  2026-09-30 Bank interest
    1000 dr 4.17
    4100 cr 4.17
TXT


posted = 0
parse_journal(text).each do |j|
  total = post(accounts, j)
  posted += 1
  puts format("#%02d %s %-20s %10s", j.no, j.date, j.memo, show(total))
rescue LedgerError => e
  puts format("#%02d %s %-20s REJECTED: %s", e.entry_no, j.date, j.memo, e.message)
end

puts
puts "Trial balance"
tdr = 0
tcr = 0
accounts.each_value do |a|
  bal = a.debits - a.credits
  next if a.debits == 0 && a.credits == 0
  dcol = bal > 0 ? show(bal) : ""
  ccol = bal < 0 ? show(-bal) : ""
  tdr += bal if bal > 0
  tcr -= bal if bal < 0
  puts format("  %s %-20s %10s %10s", a.code, a.name, dcol, ccol)
end
puts format("  %-25s %10s %10s", "", show(tdr), show(tcr))

sum_kind = accounts.values.group_by(&:kind).transform_values { |as| as.sum(&:balance) }
income = sum_kind.fetch(:income) - sum_kind.fetch(:expense)
puts
puts "Net income: #{show(income)}"
puts "Assets #{show(sum_kind.fetch(:asset))} = Liabilities #{show(sum_kind.fetch(:liability))} + Equity #{show(sum_kind.fetch(:equity) + income)}"
balanced = sum_kind.fetch(:asset) == sum_kind.fetch(:liability) + sum_kind.fetch(:equity) + income
puts "Books balance: #{balanced}; posted #{posted} entries"
