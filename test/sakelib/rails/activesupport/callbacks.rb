# ActiveSupport::Callbacks: define_callbacks / set_callback / skip_callback / run_callbacks, conditions,
# halting with throw :abort, around callbacks, a subclass's chain, a terminator, an object condition.
gem "activesupport", "8.1.3"
require "active_support"
require "active_support/callbacks"
require_relative "callbacks_decl"

class Post
  attr_accessor :title, :draft, :quiet
  def initialize(title, draft = false, quiet = false)
    @title, @draft, @quiet = title, draft, quiet
  end
  def check
    puts("  check #{title.inspect}")
    throw :abort if title.strip.empty?
  end
  def normalize
    puts("  normalize")
    self.title = title.strip
  end
  def title? = title != ""
  def draft? = draft
  def quiet? = quiet
  def wrap
    puts("  wrap {")
    yield
    puts("  } wrap")
  end
  def log_after = puts("  after #{title.inspect}")
  def audit = puts("  audit")
  def halted_callback_hook(filter, name) = puts("  halted by #{filter.inspect} in #{name.inspect}")
  def save
    run_callbacks(:save) do
      puts("  saving #{title.inspect}")
      true
    end
  end
end

class Draft < Post
  def notify = puts("  notify")
end

class Controller
  attr_accessor :user, :performed
  def initialize(user) = @user = user
  def performed? = performed
  def authenticate
    puts("  authenticate #{user.inspect}")
    self.performed = true if user.nil?
  end
  def log_action = puts("  log_action")
  def timing
    puts("  timing {")
    yield
    puts("  } timing")
  end
  def halted_callback_hook(filter, name) = puts("  halted by #{filter.inspect} in #{name.inspect}")
  def process(action) = run_callbacks(:process_action) { puts("  #{action}"); action }
end

# An object condition, as AbstractController's ActionFilter for `only:` (Ruby calls its `before`).
class OnlyActions
  def initialize(actions) = @actions = actions
  def before(controller) = @actions.include?(controller.action_name)
end

class Admin
  include ActiveSupport::Callbacks
  attr_accessor :action_name
  def initialize(action_name) = @action_name = action_name
  define_callbacks :process_action
  set_callback :process_action, :before, :load, if: OnlyActions.new(["show", "edit"])
  def load = puts("  load for #{action_name}")
  def process = run_callbacks(:process_action) { puts("  #{action_name}") }
end

puts("save:")
p(Post.new(" Hello ").save)
puts("halted:")
p(Post.new("  ").save)
puts("quiet:")
p(Post.new("q", false, true).save)
puts("destroy:")
p(Post.new("d").run_callbacks(:destroy) { puts("  destroying"); :destroyed })
puts("only before:")
p(Post.new(" b ").run_callbacks(:save, :before))
puts("no block:")
p(Post.new("n").run_callbacks(:save))
puts("_run_save_callbacks:")
p(Post.new("r")._run_save_callbacks { 42 })
puts("draft:")
p(Draft.new(" D ").save)
puts("quiet draft:")
p(Draft.new("qd", false, true).save)
puts("chains:")
p(Post._save_callbacks.map { |c| [c.kind, c.filter] })
p(Draft._save_callbacks.map { |c| [c.kind, c.filter] })
p(Post._destroy_callbacks.map { |c| [c.kind, c.filter] })
puts("skip a missing callback:")
begin
  Post.skip_callback(:save, :before, :nope)
rescue ArgumentError => e
  puts("  ArgumentError: #{e.message}")
end
Post.skip_callback(:save, :before, :nope, raise: false)
puts("terminator:")
p(Controller.new("ko1").process(:index))
p(Controller.new(nil).process(:index))
puts("object condition:")
Admin.new("show").process
Admin.new("index").process
puts("reset_callbacks:")
Post.reset_callbacks(:destroy)
p(Post._destroy_callbacks.map { |c| [c.kind, c.filter] })
p(Post.new("d").run_callbacks(:destroy) { :destroyed })
