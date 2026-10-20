# The schema of callbacks.rb/callbacks.sake (Ruby loads it; Sake's generator reads it)
ActiveRecord::Schema[8.1].define(version: 2026_10_20_000002) do
  create_table "posts", force: :cascade do |t|
    t.string "title"
    t.string "slug"
    t.boolean "locked", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "accounts", force: :cascade do |t|
    t.string "email"
    t.integer "org_id"
    t.integer "balance", default: 0
  end

  add_index "accounts", ["email", "org_id"], name: "index_accounts_on_email_and_org_id"
end
