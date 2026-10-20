gem "activerecord", "8.1.3"
require "active_record"
require "stringio"

# db/schema.rb loaded with ActiveRecord::Schema.define (its verbose output), then dumped back by the
# SchemaDumper, after a migration changed it
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
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

puts("-- load")
quietly { load File.join(__dir__, "schema_dumper_schema.rb") }
p(ActiveRecord::Base.connection.select_values("SELECT version FROM schema_migrations"))
p(ActiveRecord::Base.connection.select_values("SELECT value FROM ar_internal_metadata WHERE key = 'environment'"))

puts("-- dump")
s = StringIO.new
ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, s)
print(s.string)

class RenameRating < ActiveRecord::Migration[8.1]
  def change
    rename_column :authors, :rating, :score
    remove_column :posts, :views, :integer, default: 0
    add_column :tags, :color, :string, limit: 20, default: "red"
  end
end

puts("-- after a migration")
quietly { RenameRating.new("RenameRating", 20261020000004).migrate(:up) }
s = StringIO.new
ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection_pool, s)
print(s.string)
