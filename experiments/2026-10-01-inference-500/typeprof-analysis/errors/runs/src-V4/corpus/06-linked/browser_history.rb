class Page
  attr_accessor :url, :title, :visits, :back, :forward

  def initialize(url, title, visits, back, forward)
    @url = url
    @title = title
    @visits = visits
    @back = back
    @forward = forward
  end
end

class Tab
  attr_reader :name, :current, :opened

  def initialize(name, url)
    @name = name
    @current = Page.new(url, title_for(url), 1, nil, nil)
    @opened = 1
  end

  def visit(url)
    if url == @current.url
      @current.visits += 1
      return @current
    end
    page = Page.new(url, title_for(url), 1, @current, nil)
    @current.forward = page
    @current = page
    @opened += 1
    page
  end

  def back(steps)
    moved = 0
    while moved < steps
      prev = @current.back
      break unless prev
      @current = prev
      moved += 1
    end
    moved
  end

  def forward(steps)
    moved = 0
    while moved < steps
      nxt = @current.forward
      break unless nxt
      @current = nxt
      moved += 1
    end
    moved
  end

  def trail
    first = @current
    first = first.back while first.back
    parts = []
    page = first
    while page
      label = page.title
      label = "[#{label}]" if page.equal?(@current)
      parts << label
      page = page.forward
    end
    parts.join(" > ")
  end
end

def title_for(url)
  m = url.match(%r{\Ahttps?://([^/]+)(/[^?#]*)?})
  return url unless m
  host = m[1].delete_prefix("www.")
  path = m[2] || "/"
  path == "/" ? host : host + path
end

tab = Tab.new("main", "https://www.example.com/")
log = [
  [:visit, "https://www.example.com/docs"],
  [:visit, "https://www.example.com/docs/api?x=1"],
  [:visit, "https://news.site/today"],
  [:back, "2"],
  [:visit, "https://www.example.com/docs"],
  [:forward, "1"],
  [:visit, "https://shop.site/cart#top"],
  [:visit, "https://shop.site/checkout"],
  [:back, "5"],
  [:forward, "2"],
  [:visit, "mailto:someone"],
  [:back, "1"],
  [:forward, "9"]
]
log.each do |action, arg|
  case action
  when :visit
    tab.visit(arg)
    puts format("visit   %-38s %s", arg, tab.trail)
  when :back
    n = tab.back(arg.to_i)
    puts format("back %s  moved %-31d %s", arg, n, tab.trail)
  when :forward
    n = tab.forward(arg.to_i)
    puts format("fwd %s   moved %-31d %s", arg, n, tab.trail)
  end
end
puts "pages opened: #{tab.opened}"

cur = tab.current
puts "current: #{cur.title} (visits #{cur.visits})"
hist = []
page = cur
while page
  hist << page.url
  page = page.back
end
puts "back stack (#{hist.size}):"
hist.each_with_index { |u, i| puts "  #{i}: #{u}" }
hosts = hist.map { |u| title_for(u).split("/")[0] }.tally
puts hosts.map { |h, n| "#{h}x#{n}" }.join(" ")
