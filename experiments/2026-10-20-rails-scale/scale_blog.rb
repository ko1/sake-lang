# Writes apps/blogN/: the blog (rails/blog, copied from experiments/2026-10-12-web/rails/blog) with its Post/Comment pair copied
# N times under new names (Post1/Comment1 ... PostN/CommentN, tables post1s/comment1s, ...), on the same framework.
# usage: ruby scale_blog.rb N
require "fileutils"

n = Integer(ARGV.fetch(0))
here = __dir__
src = File.expand_path("rails/blog", here)
dst = File.join(here, "apps", "blog#{n}")
FileUtils.rm_rf(dst)

# post -> post3, posts -> post3s, Post -> Post3, PostsController -> Post3sController (and the same for comment),
# where the word is not part of a longer name (post_params and set_post are renamed; postal would not be).
def rename(text, k)
  text.gsub(/(?<![A-Za-z0-9])(post|comment|Post|Comment)(s?)(?![a-z0-9])/) { "#{$1}#{k}#{$2}" }
end

def body_of(text, opener)
  lines = text.lines
  i = lines.index { _1.start_with?(opener) } or raise "no #{opener}"
  lines[(i + 1)...lines.rindex { _1.start_with?("  end") }].join + "  end\n"
end

FileUtils.mkdir_p(%w[app/models app/controllers app/views/layouts config db bin].map { File.join(dst, _1) })
FileUtils.cp(File.join(src, "app/models/application_record.sake"), File.join(dst, "app/models"))
FileUtils.cp(File.join(src, "app/controllers/application_controller.sake"), File.join(dst, "app/controllers"))
FileUtils.cp(File.join(src, "app/views/layouts/application.html.erb"), File.join(dst, "app/views/layouts"))
framework = File.expand_path("rails", here)
rel = ->(from) { Pathname.new(framework).relative_path_from(Pathname.new(File.join(dst, from))).to_s }
require "pathname"

schema = File.read(File.join(src, "db/schema.sake"))
routes = File.read(File.join(src, "config/routes.sake"))
tables = schema[/  def define\(s\)\n(.*)\n  end\nend/m, 1]
resources = routes[/  def draw\(map\)\n(.*?)\n    root /m, 1]

(1..n).each do |k|
  %w[post comment].each do |m|
    File.write(File.join(dst, "app/models/#{m}#{k}.sake"), rename(File.read(File.join(src, "app/models/#{m}.sake")), k))
    File.write(File.join(dst, "app/controllers/#{m}#{k}s_controller.sake"),
               rename(File.read(File.join(src, "app/controllers/#{m}s_controller.sake")), k))
    FileUtils.mkdir_p(File.join(dst, "app/views/#{m}#{k}s"))
    Dir.glob(File.join(src, "app/views/#{m}s/*")).each do |f|
      File.write(File.join(dst, "app/views/#{m}#{k}s", rename(File.basename(f), k)), rename(File.read(f), k))
    end
  end
end

File.write(File.join(dst, "db/schema.sake"),
           "class ActiveRecord::Schema\n  def define(s)\n#{(1..n).map { rename(tables, _1) }.join("\n")}\n  end\nend\n")
File.write(File.join(dst, "config/routes.sake"),
           "class ActionDispatch::Routing::Mapper\n  def draw(map)\n#{(1..n).map { rename(resources, _1) }.join("\n")}\n" \
           "    root map, \"post1s#index\"\n  end\nend\n")
File.write(File.join(dst, "config/application.sake"),
           File.read(File.join(src, "config/application.sake")).sub('require "../../rails"', "require \"#{rel.("config")}/rails\""))
File.write(File.join(dst, "bin/rails.sake"),
           File.read(File.join(src, "bin/rails.sake")).sub('require "../../rails_generate"', "require \"#{rel.("bin")}/rails_generate\""))
FileUtils.cp(File.join(src, "bin/server.sake"), File.join(dst, "bin"))
puts dst
