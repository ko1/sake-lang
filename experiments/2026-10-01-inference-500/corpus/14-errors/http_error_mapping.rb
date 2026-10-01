# Route simulated HTTP requests through middleware that maps domain exceptions to status codes.
class NotFound < StandardError
  attr_reader :resource

  def initialize(message, resource)
    super(message)
    @resource = resource
  end
end

class Unauthorized < StandardError
  attr_reader :realm

  def initialize(message, realm)
    super(message)
    @realm = realm
  end
end

class Forbidden < StandardError
  attr_reader :role

  def initialize(message, role)
    super(message)
    @role = role
  end
end

class ValidationFailed < StandardError
  attr_reader :fields

  def initialize(message, fields)
    super(message)
    @fields = fields
  end
end

class RateLimited < StandardError
  attr_reader :retry_in

  def initialize(message, retry_in)
    super(message)
    @retry_in = retry_in
  end
end

class Request
  attr_reader :method, :path, :token, :body

  def initialize(method, path, token, body)
    @method = method
    @path = path
    @token = token
    @body = body
  end
end

class Response
  attr_reader :status, :body

  def initialize(status, body)
    @status = status
    @body = body
  end
end

USERS = { "1" => { name: "ann", role: "admin" }, "2" => { name: "ben", role: "viewer" } }
TOKENS = { "t-ann" => "1", "t-ben" => "2" }

def current_user(req)
  raise Unauthorized.new("missing token", "api") if req.token.nil?
  id = TOKENS[req.token] or raise Unauthorized.new("invalid token", "api")
  USERS[id]
end

def handle(req)
  m = req.path.match(%r{\A/users/(\w+)\z})
  case req.method
  when "GET"
    raise NotFound.new("no route #{req.path}", req.path) unless m
    user = USERS[m[1]] or raise NotFound.new("user #{m[1]} not found", "user")
    "#{user[:name]} (#{user[:role]})"
  when "PUT"
    me = current_user(req)
    raise Forbidden.new("admins only", me[:role]) if me[:role] != "admin"
    raise NotFound.new("no route #{req.path}", req.path) unless m
    bad = req.body.keys - ["name", "role"]
    name = req.body["name"]
    bad << "name" if name && name.length < 2
    raise ValidationFailed.new("invalid fields", bad) unless bad.empty?
    "updated #{m[1]}"
  else
    raise ArgumentError, "unsupported method"
  end
end

def with_rate_limit(counts, req, limit)
  key = req.token || "anonymous"
  counts[key] += 1
  raise RateLimited.new("too many requests", counts[key] - limit) if counts[key] > limit
  yield
end

def with_error_mapping
  Response.new(200, yield)
rescue NotFound => e
  Response.new(404, e.message)
rescue Unauthorized => e
  Response.new(401, "#{e.message} (realm #{e.realm})")
rescue Forbidden => e
  Response.new(403, "#{e.message}; you are #{e.role}")
rescue ValidationFailed => e
  Response.new(422, "#{e.message}: #{e.fields.join(", ")}")
rescue RateLimited => e
  Response.new(429, "retry in #{e.retry_in}s")
rescue ArgumentError => e
  Response.new(405, e.message)
end

requests = [
  Request.new("GET", "/users/1", nil, {}),
  Request.new("GET", "/users/9", nil, {}),
  Request.new("GET", "/teams/1", nil, {}),
  Request.new("PUT", "/users/2", nil, { "name" => "bo" }),
  Request.new("PUT", "/users/2", "t-bad", { "name" => "bo" }),
  Request.new("PUT", "/users/1", "t-ben", { "name" => "benny" }),
  Request.new("PUT", "/users/2", "t-ann", { "name" => "b", "email" => "x" }),
  Request.new("PUT", "/users/2", "t-ann", { "role" => "editor" }),
  Request.new("DELETE", "/users/2", "t-ann", {}),
  Request.new("GET", "/users/2", "t-ann", {}),
  Request.new("GET", "/users/1", "t-ann", {})
]

counts = Hash.new(0)
by_status = Hash.new(0)
log = []
requests.each do |req|
  res = with_error_mapping { with_rate_limit(counts, req, 4) { handle(req) } }
  by_status[res.status] += 1
  puts format("%-6s %-10s %d %s", req.method, req.path, res.status, res.body)
ensure
  log << req.method
end
puts "handled #{log.size} requests"
by_status.keys.sort.each { |s| puts "  #{s}: #{by_status[s]}" }
