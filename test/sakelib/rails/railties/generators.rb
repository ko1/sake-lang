# The generators of `bin/rails generate` in an app: scaffold, model, migration, controller, resource, and their log.
# Rails writes .rb files where the Sake port writes .sake ones (migrations, helpers) or a .rb class body plus a
# .sake file (controllers), so the log and the file list are printed normalized: the extensions .rb and .sake
# are dropped, a line equal to the one before it is dropped, and migration numbers are TIMESTAMP.
gem "railties", "8.1.3"
gem "activerecord", "8.1.3"
require "tmpdir"
require "stringio"
require "rails"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/generators"

dir = DIR = Dir.mktmpdir   # (the constant is for the class body)
Dir.mkdir("#{dir}/config")
File.write("#{dir}/config/database.yml", "development:\n  adapter: sqlite3\n  database: \":memory:\"\n")
File.write("#{dir}/config/routes.rb", "Rails.application.routes.draw do\n  get \"up\" => \"rails/health#show\", as: :rails_health_check\nend\n")
module Gen
  class Application < Rails::Application
    config.root = DIR
    config.load_defaults 8.1
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.generators.test_framework = nil
  end
end
Rails.application.initialize!
Rails.application.load_generators

def normalize(lines)
  out = []
  lines.each do |l|
    l = l.gsub(/\d{14}/, "TIMESTAMP").gsub(/\.(rb|sake)\b/, "")
    out << l unless out.last == l
  end
  out
end

def run_generator(dir, name, args)
  puts "-- generate #{name} #{args.join(" ")}"
  io = StringIO.new
  $stdout = io
  Rails::Generators.invoke(name, args, destination_root: dir)
  $stdout = STDOUT
  puts normalize(io.string.lines.map(&:chomp))
end

run_generator(dir, "scaffold", ["Article", "title:string", "body:text"])
run_generator(dir, "model", ["Comment", "commenter:string", "body:text", "article:references"])
run_generator(dir, "migration", ["AddViewsToArticles", "views:integer:index"])
run_generator(dir, "migration", ["RemoveBodyFromComments", "body:text"])
run_generator(dir, "controller", ["Pages", "home", "about"])
run_generator(dir, "resource", ["Tag", "name:string!:uniq"])
run_generator(dir, "model", ["User", "email:string:uniq", "password:digest"])

puts "-- files"
puts normalize(Dir.glob("{app,db}/**/*", base: dir).select { |f| File.file?(File.join(dir, f)) }.sort).uniq
puts "-- models"
Dir.glob("app/models/*.rb", base: dir).sort.each { |f| puts "# #{f}", File.read(File.join(dir, f)) }

puts "-- errors"
["x:foo", "x:string:unique"].each do |a|
  Rails::Generators::GeneratedAttribute.parse(a)
rescue Rails::Generators::Error => e
  puts e.message
end
