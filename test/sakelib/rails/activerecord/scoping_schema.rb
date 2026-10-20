# The schema of scoping.rb/scoping.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000003) do
  create_table "notes", force: :cascade do |t|
    t.string "title", null: false
    t.boolean "archived", default: false
    t.integer "rank", default: 0
  end
end
