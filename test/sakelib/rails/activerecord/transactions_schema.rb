# The schema of transactions.rb/transactions.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000004) do
  create_table "accounts", force: :cascade do |t|
    t.string "name"
    t.integer "balance", default: 0
  end
end
