# ActiveModel::Callbacks (define_model_callbacks: before/around/after, halting with throw :abort, after
# callbacks skipped when the block returns false) and ActiveModel::Validations::Callbacks (on: contexts).
gem "activemodel", "8.1.3"
require "active_model"
require_relative "callbacks_decl"

class Account
  def normalize_name
    puts("  normalize_name")
    self.name = name.strip if name
  end
  def set_default_balance
    puts("  set_default_balance")
    self.balance ||= 0
  end
  def log_validation = puts("  after_validation errors=#{errors.size}")
  def check_frozen
    puts("  check_frozen")
    throw :abort if frozen_account
  end
  def big? = balance.to_i > 100
  def announce = puts("  announce big balance")
  def wrap
    puts("  wrap {")
    yield
    puts("  } wrap")
  end
  def saved = puts("  after_save")
  def audit = puts("  audit")
  def quiet? = name == "quiet"
  def closing = puts("  closing")
  def closed = puts("  closed")

  def save(ok = true)
    return false unless valid?(:create)
    _run_save_callbacks do
      puts("  saving #{name.inspect} #{balance.inspect}")
      ok
    end
  end
  def close = _run_close_callbacks { puts("  closing now"); true }
end

puts("save:")
a = Account.new(name: "  Ann ")
p(a.save)
puts("big:")
p(Account.new(name: "Rich", balance: 500).save)
puts("invalid:")
p(Account.new(name: "  ").save)
puts("frozen:")
p(Account.new(name: "F", frozen_account: true).save)
puts("block false:")
p(Account.new(name: "B").save(false))
puts("quiet:")
p(Account.new(name: "quiet").save)
puts("valid? without context:")
b = Account.new(name: " x ")
p([b.valid?, b.name, b.balance])
puts("close:")
p(Account.new(name: "C").close)
p(Account._save_callbacks.map { [_1.kind, _1.filter] })
p(Account._validation_callbacks.map { [_1.kind, _1.filter.is_a?(Symbol) ? _1.filter : :lambda] })
