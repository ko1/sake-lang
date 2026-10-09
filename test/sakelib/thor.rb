require "thor"

# A CLI with the usual thor features: desc, method_option of each type, class_option, long_desc, an alias.
class Repo < Thor
  def self.basename = "repo"
  def self.exit_on_failure? = false

  class_option :verbose, type: :boolean, aliases: "-v", desc: "Print more"

  desc "greet NAME", "Say hello to NAME"
  long_desc "Greets NAME.\nWith --shout the greeting is upcased."
  method_option :shout, type: :boolean, aliases: "-s", desc: "Shout the greeting"
  method_option :times, type: :numeric, default: 1, aliases: "-t", desc: "How many times"
  def greet(name)
    g = "Hello, #{name}!"
    g = g.upcase if options[:shout]
    options[:times].times { puts g }
    puts "(verbose)" if options[:verbose]
  end

  desc "add FILES...", "Add FILES to the index"
  method_option :force, type: :boolean, default: false
  method_option :tags, type: :array, aliases: "-T", desc: "Tags to attach"
  def add(*files)
    puts "add #{files.inspect} force=#{options[:force].inspect} tags=#{options[:tags].inspect}"
  end

  desc "commit", "Record changes"
  method_option :message, type: :string, required: true, aliases: "-m", banner: "MSG", desc: "Commit message"
  method_option :author, type: :string, default: "me", desc: "Author name"
  method_option :level, type: :numeric, enum: [1, 2, 3], default: 1
  def commit
    puts "commit message=#{options[:message].inspect} author=#{options[:author].inspect} level=#{options[:level].inspect}"
  end

  desc "config KEY [VALUE]", "Get or set KEY"
  def config(key, value = nil)
    puts "config #{key}=#{value.inspect}"
  end

  desc "tag NAME", "Tag with NAME", hide: true
  def tag(name)
    puts "tag #{name}"
  end

  map "ci" => :commit
  map ["--version", "-V"] => :version

  desc "version", "Print the version"
  def version
    puts "repo 1.0"
  end
end

def run(argv)
  puts "$ repo #{argv.join(" ")}"
  Repo.start(argv, debug: true)
rescue Thor::Error => e
  puts e.message
end

run(["greet", "World"])
run(["greet", "World", "--shout"])
run(["greet", "World", "-s", "-t", "2"])
run(["greet", "--times=3", "Bob"])
run(["greet", "World", "--no-shout", "--verbose"])
run(["greet", "World", "-v", "--times", "0"])
run(["add", "a.rb", "b.rb", "--force", "--tags", "x", "y"])
run(["add", "--tags=one", "--", "c.rb"])
run(["add", "a.rb", "-T", "t1", "t2", "--no-force"])
run(["commit", "-m", "first"])
run(["commit", "--message", "second", "--author", "ko1", "--level", "3"])
run(["ci", "--message=third"])
run(["config", "user"])
run(["config", "user", "ko1"])
run(["tag", "v1"])
run(["version"])
run(["--version"])
run(["-V"])
run([])
run(["help"])
run(["help", "greet"])
run(["help", "add"])
run(["help", "commit"])
run(["help", "config"])
run(["greet", "--help"])
run(["greet"])
run(["greet", "a", "b"])
run(["config"])
run(["config", "a", "b", "c"])
run(["commit"])
run(["commit", "-m", "x", "--level", "9"])
run(["commit", "-m", "x", "--level", "abc"])
run(["greet", "World", "--times", "abc"])
run(["greet", "World", "--bogus"])
run(["greet", "World", "-x"])
run(["commit", "--message"])
run(["push"])
run(["help", "push"])
