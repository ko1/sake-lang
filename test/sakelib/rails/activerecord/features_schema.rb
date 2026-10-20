# The schema of features.rb/features.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000003) do
  create_table "orders", force: :cascade do |t|
    t.string "code"
    t.integer "status", default: 0
    t.string "priority"
    t.text "settings"
    t.string "token"
    t.integer "items_count", default: 0
    t.boolean "paid", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "docs", force: :cascade do |t|
    t.string "title"
    t.integer "lock_version", default: 0
  end

  create_table "notes", force: :cascade do |t|
    t.string "body"
    t.datetime "created_at"
    t.datetime "updated_at"
  end
end
