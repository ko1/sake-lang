# The schema of base.rb/base.sake, in db/schema.rb's form (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000001) do
  create_table "posts", force: :cascade do |t|
    t.string "title", null: false
    t.text "body"
    t.integer "views", default: 0
    t.boolean "published", default: false
    t.decimal "score", precision: 5, scale: 2
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end
end
