# The schema of relation.rb/relation.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000002) do
  create_table "items", force: :cascade do |t|
    t.string "name", null: false
    t.string "category"
    t.integer "price", default: 0
    t.integer "stock"
    t.boolean "active", default: true
    t.integer "hits", default: 0
  end
end
