# The schema of associations.rb/associations.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000002) do
  create_table "authors", force: :cascade do |t|
    t.string "name"
  end
  create_table "profiles", force: :cascade do |t|
    t.integer "author_id"
    t.string "bio"
  end
  create_table "posts", force: :cascade do |t|
    t.integer "author_id"
    t.string "title"
    t.integer "comments_count", default: 0
  end
  create_table "comments", force: :cascade do |t|
    t.integer "post_id"
    t.string "body"
    t.boolean "approved", default: false
  end
  create_table "tags", force: :cascade do |t|
    t.string "name"
  end
  create_table "taggings", force: :cascade do |t|
    t.integer "post_id"
    t.integer "tag_id"
  end
  create_table "categories", force: :cascade do |t|
    t.string "name"
  end
  create_table "categories_posts", id: false, force: :cascade do |t|
    t.integer "category_id"
    t.integer "post_id"
  end
end
