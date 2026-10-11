require "rss"

# fixed zone for the dates the gem converts to local time
ENV["TZ"] = "UTC"

# an RSS 2.0 document
rss_xml = <<~XML
  <?xml version="1.0" encoding="UTF-8"?>
  <rss version="2.0">
    <channel>
      <title>Sake News</title>
      <link>https://example.com/</link>
      <description>All about &lt;Sake&gt; &amp; more</description>
      <language>ja</language>
      <copyright>2024 Example</copyright>
      <pubDate>Tue, 02 Jan 2024 03:04:05 GMT</pubDate>
      <lastBuildDate>Wed, 03 Jan 2024 09:00:00 +0900</lastBuildDate>
      <generator>hand</generator>
      <ttl>60</ttl>
      <image>
        <url>https://example.com/logo.png</url>
        <title>Sake News</title>
        <link>https://example.com/</link>
        <width>88</width>
      </image>
      <item>
        <title>First post</title>
        <link>https://example.com/1</link>
        <description><![CDATA[<p>Hello</p>]]></description>
        <author>ann@example.com (Ann)</author>
        <category domain="https://example.com/tags">lang</category>
        <category>news</category>
        <guid isPermaLink="false">post-1</guid>
        <pubDate>Mon, 01 Jan 2024 10:00:00 +0000</pubDate>
        <enclosure url="https://example.com/1.mp3" length="1234" type="audio/mpeg"/>
      </item>
      <item>
        <title>Second post</title>
        <link>https://example.com/2</link>
        <guid>https://example.com/2</guid>
        <comments>https://example.com/2#c</comments>
      </item>
    </channel>
  </rss>
XML

rss = RSS::Parser.parse(rss_xml)
p(rss.feed_type)
p(rss.feed_version)
p(rss.rss_version)
ch = rss.channel
p(ch.title)
p(ch.link)
p(ch.description)
p(ch.language)
p(ch.copyright)
pub_date = ch.pubDate
p(pub_date.utc.iso8601)
last_build = ch.lastBuildDate
p(last_build.utc.iso8601)
p(ch.generator)
p(ch.ttl)
image = ch.image
p(image.url)
p(image.width)
p(image.height)
p(rss.items.size)
rss.items.each do |item|
  puts("-- #{item.title}")
  p(item.link)
  p(item.description)
  p(item.author)
  p(item.categories.map { |c| [c.domain, c.content] })
  guid = item.guid
  p(guid.content)
  p(guid.isPermaLink)
  p(guid.PermaLink?)
  date = item.pubDate
  p(date ? date.utc.iso8601 : nil)
  p(item.comments)
  enc = item.enclosure
  p(enc ? [enc.url, enc.length, enc.type] : nil)
end
puts(rss.to_s)

# an Atom document
atom_xml = <<~XML
  <?xml version="1.0" encoding="utf-8"?>
  <feed xmlns="http://www.w3.org/2005/Atom">
    <title type="text">Example Feed</title>
    <subtitle>A subtitle.</subtitle>
    <link href="http://example.org/feed/" rel="self"/>
    <link href="http://example.org/"/>
    <id>urn:uuid:60a76c80-d399-11d9-b91C-0003939e0af6</id>
    <updated>2003-12-13T18:30:02Z</updated>
    <author>
      <name>John Doe</name>
      <email>johndoe@example.com</email>
    </author>
    <category term="tech" label="Technology"/>
    <generator uri="https://example.org/gen" version="1.0">Gen</generator>
    <entry>
      <title>Atom-Powered Robots Run Amok</title>
      <link href="http://example.org/2003/12/13/atom03"/>
      <link rel="alternate" type="text/html" href="http://example.org/2003/12/13/atom03.html"/>
      <id>urn:uuid:1225c695-cfb8-4ebb-aaaa-80da344efa6a</id>
      <updated>2003-12-13T18:30:02+09:00</updated>
      <published>2003-12-12T08:00:00Z</published>
      <summary>Some text.</summary>
      <content type="html">&lt;p&gt;Body&lt;/p&gt;</content>
    </entry>
    <entry>
      <title>Second</title>
      <id>urn:uuid:2</id>
      <updated>2003-12-14T00:00:00Z</updated>
      <author><name>Jane</name><uri>https://jane.example</uri></author>
    </entry>
  </feed>
XML

feed = RSS::Parser.parse(atom_xml)
p(feed.feed_type)
title = feed.title
p(title.content)
p(title.type)
subtitle = feed.subtitle
p(subtitle.content)
id = feed.id
p(id.content)
updated = feed.updated
updated_at = updated.content
p(updated_at.utc.iso8601)
p(feed.links.map { |l| [l.href, l.rel] })
link = feed.link
p(link.href)
author = feed.author
author_name = author.name
p(author_name.content)
author_email = author.email
p(author_email.content)
p(feed.categories.map { |c| [c.term, c.label] })
gen = feed.generator
p([gen.content, gen.uri, gen.version])
p(feed.entries.size)
feed.entries.each do |entry|
  entry_title = entry.title
  puts("-- #{entry_title.content}")
  entry_id = entry.id
  p(entry_id.content)
  entry_updated = entry.updated
  updated_time = entry_updated.content
  p(updated_time.utc.iso8601)
  published = entry.published
  published_time = published ? published.content : nil
  p(published_time ? published_time.utc.iso8601 : nil)
  p(entry.links.map { |l| [l.href, l.rel, l.type] })
  summary = entry.summary
  p(summary ? summary.content : nil)
  content = entry.content
  p(content ? [content.type, content.content] : nil)
  p(entry.authors.map do |a|
    name = a.name
    uri = a.uri
    [name ? name.content : nil, uri ? uri.content : nil]
  end)
end
puts(feed.to_s)

# making RSS 2.0
made = RSS::Maker.make("2.0") do |maker|
  maker.channel.title = "Made & Sent"
  maker.channel.link = "https://example.com/"
  maker.channel.description = "Made <by> maker"
  maker.channel.language = "en"
  maker.channel.updated = Time.utc(2024, 1, 2, 3, 4, 5)
  maker.items.new_item do |item|
    item.title = "One"
    item.link = "https://example.com/1"
    item.description = "first"
    item.updated = Time.utc(2024, 1, 1, 0, 0, 0)
    item.guid.content = "id-1"
    item.guid.isPermaLink = false
  end
  maker.items.new_item do |item|
    item.title = "Two"
    item.link = "https://example.com/2"
    item.author = "bob@example.com"
    item.categories.new_category { |c| c.content = "news" }
  end
end
puts(made.to_s)
p(made.items.map { |i| i.title })

# making Atom
made_atom = RSS::Maker.make("atom") do |maker|
  maker.channel.author = "Ann"
  maker.channel.updated = Time.utc(2024, 1, 2, 3, 4, 5)
  maker.channel.about = "urn:uuid:feed"
  maker.channel.title = "Atom <Made>"
  maker.channel.links.new_link { |l| l.href = "https://example.com/"; l.rel = "alternate" }
  maker.items.new_item do |item|
    item.link = "https://example.com/a1"
    item.title = "Entry one"
    item.updated = Time.utc(2024, 1, 1)
    item.summary = "sum & more"
  end
end
puts(made_atom.to_s)

# round trip: what the maker made parses back
again = RSS::Parser.parse(made.to_s)
again_channel = again.channel
p(again_channel.title)
p(again.items.map { |i| i.link })
back = RSS::Parser.parse(made_atom.to_s)
back_title = back.title
p(back_title.content)
first = back.entries.first
first_summary = first.summary
p(first_summary.content)

# errors: missing required elements, not XML, not a feed
begin
  RSS::Parser.parse("<rss version=\"2.0\"><channel><title>t</title><link>l</link></channel></rss>")
rescue RSS::MissingTagError => e
  puts(e.message)
end
begin
  RSS::Parser.parse("<rss version=\"2.0\"><channel><title>t</title>")
rescue RSS::NotWellFormedError => e
  puts("not well formed")
end
p(RSS::Parser.parse("<html><body/></html>"))
begin
  RSS::Maker.make("2.0") do |maker|
    maker.channel.title = "t"
    maker.channel.link = "l"
  end
rescue RSS::NotSetError => e
  puts(e.message)
end
begin
  RSS::Maker.make("3.0") { |maker| }
rescue RSS::UnsupportedMakerVersionError => e
  puts(e.message)
end
# without validation, the missing description is allowed
loose = RSS::Parser.parse("<rss version=\"2.0\"><channel><title>t</title><link>l</link></channel></rss>", false)
loose_channel = loose.channel
p(loose_channel.title)
p(loose_channel.description)
