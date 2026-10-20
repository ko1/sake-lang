gem "activerecord", "8.1.3"
require "active_record"
require "stringio"

# Migrations: change (inverted by the CommandRecorder on the way down), up/down, reversible, the verbose
# output, schema_migrations and ar_internal_metadata, MigrationContext migrate/rollback/status, and the SQL
# that changes the database (SQLite's alter_table copies the table)
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
SQL = []
ActiveSupport::Notifications.subscribe("sql.active_record") { |*, payload| SQL << payload[:sql] }
def show_sql
  SQL.each do |sql|
    next unless sql.match?(/\A\s*(CREATE|ALTER|DROP|INSERT|DELETE|UPDATE|PRAGMA (defer_)?foreign_keys =)/)
    puts("  sql: #{sql.gsub(/'\d{4}-\d\d-\d\d \d\d:\d\d:\d\d\.\d+'/, "'TIME'")}")
  end
  SQL.clear
end
# what migrations print, with the times made fixed
def quietly
  out = StringIO.new
  old = $stdout
  $stdout = out
  begin
    yield
  ensure
    $stdout = old
  end
  print(out.string.gsub(/\d+\.\d+s/, "0.0000s"))
end

class CreatePosts < ActiveRecord::Migration[8.1]
  def change
    create_table :posts do |t|
      t.string :title, null: false
      t.text :body
      t.timestamps
    end
    add_index :posts, :title, unique: true
  end
end

class AddViewsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :views, :integer, default: 0
    rename_column :posts, :body, :content
    reversible do |dir|
      dir.up { say "views start at 0" }
      dir.down { say "views are gone" }
    end
  end
end

class CreateTags < ActiveRecord::Migration[8.1]
  def up
    create_table :tags do |t|
      t.string :name
    end
    execute "INSERT INTO tags (name) VALUES ('ruby')"
  end

  def down
    drop_table :tags
  end
end

class ChangeViews < ActiveRecord::Migration[8.1]
  def change
    change_column_default :posts, :views, from: 0, to: 1
    change_column_null :posts, :content, false, ""
  end
end

class DropTags < ActiveRecord::Migration[8.1]
  def change
    drop_table :tags
  end
end

# Ruby reads migration files; the list is given here (the Sake side has no files either)
class ListContext < ActiveRecord::MigrationContext
  def initialize(list)
    @list = list
    super("db/migrate")
  end

  def migrations = @list
end

list = [CreatePosts.new("CreatePosts", 20261020000001), AddViewsToPosts.new("AddViewsToPosts", 20261020000002),
        CreateTags.new("CreateTags", 20261020000003), ChangeViews.new("ChangeViews", 20261020000004)]
ctx = ListContext.new(list)

puts("-- migrate")
p(ctx.needs_migration?)
quietly { ctx.migrate }
show_sql
p([ctx.current_version, ctx.needs_migration?])
p(ctx.migrations_status)
p(ActiveRecord::Base.connection.select_rows("SELECT name FROM tags"))
p(ActiveRecord::Base.connection.columns("posts").map { |c| [c.name, c.sql_type, c.null, c.default] })

puts("-- rollback")
quietly { ctx.rollback(2) }
show_sql
p(ctx.current_version)
p(ActiveRecord::Base.connection.tables.sort)
p(ActiveRecord::Base.connection.columns("posts").map { |c| [c.name, c.sql_type, c.null, c.default] })

puts("-- migrate to a version, and down")
quietly { ctx.migrate(20261020000003) }
show_sql
quietly { ctx.migrate(20261020000001) }
show_sql
p(ctx.current_version)
p(ActiveRecord::Base.connection.columns("posts").map(&:name))
begin
  ctx.migrate(20261020000009)
rescue ActiveRecord::UnknownMigrationVersionError => e
  puts("UnknownMigrationVersionError: #{e.message.strip}")
end

puts("-- irreversible")
begin
  quietly { DropTags.new("DropTags", 20261020000005).migrate(:down) }
rescue ActiveRecord::IrreversibleMigration => e
  puts("IrreversibleMigration: #{e.message.strip}")
end
SQL.clear
