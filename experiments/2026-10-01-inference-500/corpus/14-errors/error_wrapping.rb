# Layered loading of user profiles: low-level errors are wrapped into higher-level ones, keeping a cause chain.
class StorageError < StandardError
  attr_reader :key

  def initialize(message, key)
    super(message)
    @key = key
  end
end

class DecodeError < StandardError
  attr_reader :field

  def initialize(message, field)
    super(message)
    @field = field
  end
end

class ProfileError < StandardError
  attr_reader :user_id

  def initialize(message, user_id)
    super(message)
    @user_id = user_id
  end
end

STORAGE = {
  "user:1" => "name=Ann;age=34;langs=ruby,c",
  "user:2" => "name=Ben;age=x7;langs=go",
  "user:3" => "name=;age=41;langs=",
  "user:4" => "corrupted-bytes",
  "user:6" => "name=Eve;age=29;langs=rust,ocaml,sql",
  "user:7" => "name=Gus;langs=c"
}

def read_raw(key)
  STORAGE[key] or raise StorageError.new("key #{key} not found", key)
end

def decode(raw)
  fields = raw.split(";").to_h do |part|
    k, sep, v = part.partition("=")
    raise DecodeError.new("malformed pair '#{part}'", "*") if sep.empty?
    [k, v]
  end
  name = fields["name"]
  raise DecodeError.new("name is missing", "name") if name.nil? || name.empty?
  age = begin
    Integer(fields.fetch("age"))
  rescue ArgumentError, KeyError
    raise DecodeError.new("age is not a number", "age")
  end
  langs = fields.fetch("langs", "").split(",").reject(&:empty?)
  { name:, age:, langs: }
end

def load_profile(id)
  decode(read_raw("user:#{id}"))
rescue StorageError
  raise ProfileError.new("profile #{id} unavailable", id)
rescue DecodeError
  raise ProfileError.new("profile #{id} is invalid", id)
end

def chain(e)
  links = []
  current = e
  while current
    links << case current
             when ProfileError then "ProfileError: #{current.message}"
             when DecodeError then "DecodeError(#{current.field}): #{current.message}"
             when StorageError then "StorageError: #{current.message}"
             else current.class.name
             end
    current = current.cause
  end
  links
end

loaded = []
(1..7).each do |id|
  profile = load_profile(id)
  loaded << profile
  langs = profile[:langs]
  puts "#{id}: #{profile[:name]} (#{profile[:age]}) #{langs.empty? ? "no languages" : langs.join("/")}"
rescue ProfileError => e
  first, *rest = chain(e)
  puts "#{id}: #{first}"
  rest.each { |l| puts "     caused by #{l}" }
end
ages = loaded.map { |r| r[:age] }
puts "loaded #{loaded.size}; mean age #{ages.sum / ages.size}"
