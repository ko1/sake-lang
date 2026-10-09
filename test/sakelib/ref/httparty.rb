# A plain-Ruby reference for the HTTParty API that sakelib/httparty.sake ports (the gem is not installed here):
# HTTParty.get/post/put/patch/delete/head(url, query:, headers:, body:, basic_auth:) over Net::HTTP, a Response with
# code, body, headers, parsed_response (JSON for a JSON content type), success?, and the class DSL as a client object.
require "net/http"
require "uri"
require "json"

module HTTParty
  class RedirectionTooDeep < StandardError; end

  class Response
    attr_reader :code, :body, :headers, :request_uri, :response, :parsed_response, :message

    def initialize(code, body, headers, request_uri, response, message)
      @code, @body, @headers, @request_uri, @response, @message = code, body, headers, request_uri, response, message
      @parsed_response = HTTParty._parse(body, headers["content-type"])
    end

    def success? = code >= 200 && code < 300
    def ok? = code == 200
    def redirection? = code >= 300 && code < 400
    def client_error? = code >= 400 && code < 500
    def server_error? = code >= 500 && code < 600
    def not_found? = code == 404
    def unauthorized? = code == 401
    def forbidden? = code == 403
    def bad_request? = code == 400
    def nil? = body.nil? || body.empty?
    def content_type = response.content_type
    def content_length = response.content_length
    def header(name) = headers[name.downcase]
    def [](k) = parsed_response[k]
    def to_s = body || ""
    def inspect = "#<HTTParty::Response:0x code=#{code} body=#{body.inspect} message=#{message.inspect} headers=#{headers.inspect}>"
  end

  module_function

  def to_params(hash) = hash.map { |k, v| normalize_param(k, v) }.join("&")

  def normalize_param(key, value)
    case value
    when Array then value.map { |v| normalize_param("#{key}[]", v) }.join("&")
    when Hash then value.map { |k, v| normalize_param("#{key}[#{k}]", v) }.join("&")
    when nil then URI.encode_www_form_component(key.to_s)
    else "#{URI.encode_www_form_component(key.to_s)}=#{URI.encode_www_form_component(value.to_s)}"
    end
  end

  def _parse(body, content_type)
    return nil if body.nil?
    ct = (content_type || "").downcase
    if ct.match?(/\A\s*(?:application\/(?:hal\+|problem\+|vnd\.api\+)?json|text\/json|application\/x-javascript|text\/javascript)/)
      body.empty? ? nil : JSON.parse(body)
    else
      body
    end
  end

  def _uri(url, query)
    u = url.is_a?(URI::Generic) ? url.dup : URI.parse(url)
    if query && !query.empty?
      extra = to_params(query)
      u.query = u.query.nil? || u.query.empty? ? extra : "#{u.query}&#{extra}"
    end
    u
  end

  def _request(method, url, query, headers, body, basic_auth, timeout, follow_redirects, limit)
    u = _uri(url, query)
    req = Net::HTTPGenericRequest.new(method, !body.nil?, method != "HEAD", u.request_uri, headers || {})
    if body
      req.body = body.is_a?(Hash) ? to_params(body) : body.to_s
      req["Content-Type"] ||= "application/x-www-form-urlencoded"
    end
    req.basic_auth(basic_auth[:username].to_s, basic_auth[:password].to_s) if basic_auth
    http = Net::HTTP.new(u.hostname, u.port)
    http.use_ssl = u.scheme == "https"
    http.open_timeout = http.read_timeout = timeout
    res = http.start { |h| h.request(req) }
    code = res.code.to_i
    if follow_redirects && res["location"] && [301, 302, 303, 307, 308].include?(code)
      raise RedirectionTooDeep, "HTTP redirects too deep" if limit <= 0
      meth = (code == 303 || ([301, 302].include?(code) && method == "POST")) ? "GET" : method
      return _request(meth, u.merge(res["location"]), nil, headers, meth == "GET" ? nil : body, basic_auth, timeout, true, limit - 1)
    end
    hdrs = {}
    res.each_header { |k, v| hdrs[k] = v }
    Response.new(code, res.body, hdrs, u, res, res.message)
  end

  def get(url, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("GET", url, query, headers, nil, basic_auth, timeout, follow_redirects, 5)
  def head(url, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("HEAD", url, query, headers, nil, basic_auth, timeout, follow_redirects, 5)
  def delete(url, query: nil, headers: nil, body: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("DELETE", url, query, headers, body, basic_auth, timeout, follow_redirects, 5)
  def options(url, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("OPTIONS", url, query, headers, nil, basic_auth, timeout, follow_redirects, 5)
  def post(url, body: nil, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("POST", url, query, headers, body, basic_auth, timeout, follow_redirects, 5)
  def put(url, body: nil, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("PUT", url, query, headers, body, basic_auth, timeout, follow_redirects, 5)
  def patch(url, body: nil, query: nil, headers: nil, basic_auth: nil, timeout: 60, follow_redirects: true) = _request("PATCH", url, query, headers, body, basic_auth, timeout, follow_redirects, 5)

  # The class DSL (`include HTTParty; base_uri ...; headers ...; default_params ...`) as an object.
  class Client
    attr_reader :base_uri
    attr_accessor :headers, :default_params, :basic_auth, :timeout

    def initialize(base_uri, headers: {}, default_params: {}, basic_auth: nil, timeout: 60)
      @base_uri, @headers, @default_params, @basic_auth, @timeout = base_uri, headers, default_params, basic_auth, timeout
    end

    def _url(path) = base_uri.end_with?("/") && path.start_with?("/") ? base_uri + path[1..] : base_uri + path
    def _query(query) = query ? default_params.merge(query) : default_params
    def _headers(h) = h ? headers.merge(h) : headers

    def get(path, query: nil, headers: nil) = HTTParty.get(_url(path), query: _query(query), headers: _headers(headers), basic_auth: basic_auth, timeout: timeout)
    def head(path, query: nil, headers: nil) = HTTParty.head(_url(path), query: _query(query), headers: _headers(headers), basic_auth: basic_auth, timeout: timeout)
    def delete(path, query: nil, headers: nil, body: nil) = HTTParty.delete(_url(path), query: _query(query), headers: _headers(headers), body: body, basic_auth: basic_auth, timeout: timeout)
    def post(path, body: nil, query: nil, headers: nil) = HTTParty.post(_url(path), body: body, query: _query(query), headers: _headers(headers), basic_auth: basic_auth, timeout: timeout)
    def put(path, body: nil, query: nil, headers: nil) = HTTParty.put(_url(path), body: body, query: _query(query), headers: _headers(headers), basic_auth: basic_auth, timeout: timeout)
    def patch(path, body: nil, query: nil, headers: nil) = HTTParty.patch(_url(path), body: body, query: _query(query), headers: _headers(headers), basic_auth: basic_auth, timeout: timeout)
  end
end
