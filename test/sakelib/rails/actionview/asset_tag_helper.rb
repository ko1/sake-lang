gem "actionview", "8.1.3"
require "action_view"
require "action_dispatch"

# A view with an app's settings: config.asset_host, a CSP nonce, forgery protection (a controller gives these)
class AppView < ActionView::Base
  def config = ActiveSupport::InheritableOptions.new(asset_host: "assets%d.example.com", relative_url_root: "/app")

  def content_security_policy? = true
  def content_security_policy_nonce = "n0nce"
  def protect_against_forgery? = true
  def form_authenticity_token(form_options: nil) = "t0ken"
  def request_forgery_protection_token = :authenticity_token
  attr_accessor :request
end

view = ActionView::Base.empty
V = view
req = ActionDispatch::Request.new(Rack::MockRequest.env_for("http://www.example.com/"))
req.content_security_policy_nonce_directives = ["script-src"]
app = AppView.empty.tap { _1.request = req }

# asset paths
puts V.asset_path("application.js")
puts V.asset_path("application", type: :javascript)
puts V.asset_path("application.js", type: :javascript)
puts V.asset_path("/images/logo.png?v=1#top")
puts V.asset_path("http://example.com/a.js")
puts V.asset_path("//cdn.example.com/a.js")
p V.asset_path("")
puts V.image_path("edit.png")
puts V.image_path("edit.png", host: "cdn.example.com")
puts V.image_path("edit.png", host: "cdn.example.com", protocol: :https)
puts V.image_url("edit.png", host: "http://cdn.example.com")
puts V.javascript_path("xmlhr")
puts V.javascript_path("xmlhr", extname: false)
puts V.stylesheet_path("style")
puts V.stylesheet_url("style", host: "http://a.example.com")
puts V.font_path("font.ttf"), V.video_path("hd.avi"), V.audio_path("horse.wav")
puts app.image_path("logo.png")
puts app.javascript_path("app"), app.stylesheet_path("style"), app.asset_path("/app/x.css")
begin
  V.asset_path(nil)
rescue ArgumentError => e
  puts e.message
end
# tags
puts V.javascript_include_tag("xmlhr")
puts V.javascript_include_tag("common", "elsewhere", "common", defer: true)
puts V.javascript_include_tag("http://www.example.com/xmlhr.js", crossorigin: true, type: "module")
puts app.javascript_include_tag("app", nonce: true)
puts V.javascript_include_tag("a", nonce: false, async: true)
puts V.stylesheet_link_tag("style")
puts V.stylesheet_link_tag("style", media: "all", host: "s.example.com")
puts V.stylesheet_link_tag("random.styles", "/elsewhere/file")
puts app.stylesheet_link_tag("style", nonce: true)
puts V.auto_discovery_link_tag(:rss, "/feed.rss")
puts V.auto_discovery_link_tag(:atom, "http://www.example.com/feed.atom", { title: "My Atom" })
puts V.auto_discovery_link_tag(:json, "/feed.json")
puts V.auto_discovery_link_tag(:rss, "/feed", { rel: "feed", type: "application/x-rss" })
begin
  V.auto_discovery_link_tag(:xml, "/feed")
rescue ArgumentError => e
  puts e.message
end
puts V.favicon_link_tag
puts V.favicon_link_tag("myicon.png", rel: "apple-touch-icon", type: "image/png")
puts app.preload_link_tag("application.js")
puts app.preload_link_tag("style.css", fetchpriority: "high")
puts app.preload_link_tag("/fonts/a.woff2", type: "font/woff2")
puts app.preload_link_tag("/media/audio.ogg", nopush: true)
puts app.preload_link_tag("/v.mp4", as: "video", crossorigin: true)
puts V.image_tag("icon.png")
puts V.image_tag("icon.png", alt: "Edit", size: "16x10", class: "i")
puts V.image_tag("icon.png", size: "20")
puts V.image_tag("icon.png", size: "x")
puts V.image_tag("/icons/icon.gif", height: 32, width: 32)
puts V.image_tag("http://example.com/a.png", srcset: { "a-2x.png" => "2x", "a-3x.png" => "3x" })
puts V.image_tag("a.png", srcset: [["a-1.png", "100w"], ["a-2.png", "200w"]], sizes: "50vw")
puts V.image_tag("a.png", srcset: "x.png 2x")
begin
  V.image_tag("a.png", size: "1x1", width: 3)
rescue ArgumentError => e
  puts e.message
end
puts V.picture_tag("icon.webp")
puts V.picture_tag("icon.webp", "icon.png", class: "p", image: { alt: "Icon" })
puts V.picture_tag(id: "pic") { V.image_tag("inside.png") }
puts V.video_tag("trailer")
puts V.video_tag("trailer.ogg", controls: true, preload: "none", poster: "screen.png", size: "16x10")
puts V.video_tag("trailer.ogg", "trailer.flv", autoplay: true)
puts V.video_tag("/trailers/hd.avi", size: "16")
puts V.audio_tag("sound")
puts V.audio_tag("sound.wav", "sound.mid", autoplay: true, controls: true)
# csrf and csp
p V.csrf_meta_tags
puts app.csrf_meta_tags
puts app.csrf_meta_tag
puts app.csp_meta_tag
puts app.csp_meta_tag(id: "csp")
