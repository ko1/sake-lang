gem "activesupport", "8.1.3"
require "active_support"
require "active_support/core_ext/module/delegation"

# Module#delegate (core_ext/module/delegation, delegation)
class User
  attr_reader :name, :email
  def initialize(name, email) = (@name, @email = name, email)
  def greet(other) = "hi #{other}, I am #{@name}"
end

class Post
  attr_reader :title, :author
  def initialize(title, author) = (@title, @author = title, author)
  delegate :name, :greet, to: :author
  delegate :name, :email, to: :author, prefix: true, allow_nil: true
  delegate :email, to: :author, prefix: :writer
end

post = Post.new("Hello", User.new("ann", "ann@example.com"))
p(post.name, post.greet("bob"), post.author_name, post.author_email, post.writer_email)
orphan = Post.new("Orphan", nil)
p(orphan.author_name)
begin
  orphan.name
rescue ActiveSupport::DelegationError => e
  puts e.message
end
begin
  orphan.name
rescue NoMethodError => e
  puts e.class.name
end
puts(<<~SAKE)
  def Post.author_name(obj)
    target = @author
    target ? User.name(target) : nil
  end
SAKE
