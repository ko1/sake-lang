# db/schema.rb of schema_dumper.rb/.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000003) do
  create_table "authors", force: :cascade do |t|
    t.string "name", limit: 80, null: false
    t.date "born_on"
    t.float "rating"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "author_id"
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "published", default: false
    t.decimal "score", precision: 5, scale: 2
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.integer "views", default: 0
    t.index ["author_id"], name: "index_posts_on_author_id"
    t.index ["title"], name: "index_posts_on_title", unique: true
  end

  create_table "tags", id: false, force: :cascade do |t|
    t.string "name"
    t.integer "post_id"
  end

  create_table "settings", primary_key: "key", id: :string, force: :cascade do |t|
    t.string "value", default: "on"
  end
end
