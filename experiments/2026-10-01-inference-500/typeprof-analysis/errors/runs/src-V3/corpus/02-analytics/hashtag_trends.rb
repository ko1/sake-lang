require "set"

class Post
  attr_reader :day, :author, :text

  def initialize(day, author, text)
    @day = day
    @author = author
    @text = text
  end
end

def posts
  [
    Post.new(1, "ana", "Loving the new #ruby release! #programming"),
    Post.new(1, "ben", "@ana agreed, #ruby keeps getting faster #perf"),
    Post.new(1, "cy", "Coffee first, then #programming. #mondays"),
    Post.new(1, "dee", "#mondays are hard @cy @ben"),
    Post.new(2, "ana", "Benchmarks are in: #perf wins across the board #ruby"),
    Post.new(2, "ben", "#perf #perf #perf (sorry) @ana"),
    Post.new(2, "eve", "Anyone else trying #typeinference? @ana @ben"),
    Post.new(2, "cy", "#typeinference without annotations sounds like magic"),
    Post.new(3, "dee", "Reading about #typeinference and #ruby @eve"),
    Post.new(3, "eve", "#TypeInference talk slides are up! #programming"),
    Post.new(3, "ana", "@eve great talk #typeinference"),
    Post.new(3, "fay", "first post, hello world #hello")
  ]
end

def tags(text) = text.scan(/#(\w+)/).map { |m| m[0].downcase }.uniq
def mentions(text) = text.scan(/@(\w+)/).map { |m| m[0] }

daily = {}
mention_graph = {}
tag_authors = {}
posts.each do |pt|
  counts = daily[pt.day] ||= Hash.new(0)
  tags(pt.text).each do |t|
    counts[t] += 1
    (tag_authors[t] ||= Set[]) << pt.author
  end
  mentions(pt.text).each do |m|
    targets = mention_graph[pt.author] ||= Hash.new(0)
    targets[m] += 1
  end
end

days = daily.keys.sort
all_tags = daily.values.flat_map(&:keys).uniq.sort
puts format("%-14s", "tag") + days.map { |d| format("%5s", "d#{d}") }.join + "  authors"
all_tags.each do |t|
  row = days.map { |d| format("%5d", daily[d][t]) }
  puts format("%-14s", "#" + t) + row.join + "  #{tag_authors[t].size}"
end

def trend(daily, tag, from, to)
  before = daily[from][tag]
  after = daily[to][tag]
  return nil if before + after < 2
  (after - before) * 1.0 / (before + 1)
end

scores = all_tags.filter_map do |t|
  s = trend(daily, t, 1, 3)
  s ? [t, s] : nil
end
rising = scores.sort_by { |t, s| [-s, t] }
puts "trend day1 -> day3:"
rising.each { |t, s| puts format("  #%-13s %+.2f", t, s) }

puts "mentions:"
mention_graph.keys.sort.each do |who|
  targets = mention_graph[who]
  parts = targets.keys.sort.map { |t| "#{t}x#{targets[t]}" }
  puts "  #{who} -> #{parts.join(" ")}"
end

received = Hash.new(0)
mention_graph.each { |_, targets| targets.each { |t, n| received[t] += n } }
star = received.max_by { |_, n| n }
if star
  who, n = star
  puts "most mentioned: @#{who} (#{n})"
end
mutual = []
mention_graph.each do |a, targets|
  targets.each_key do |b|
    back = mention_graph[b]
    mutual << "#{a}<->#{b}" if a < b && back && back.key?(a)
  end
end
puts "mutual mentions: #{mutual.sort.join(", ")}"
silent = posts.map(&:author).uniq.sort
silent = silent.reject { |a| mention_graph.key?(a) || received.key?(a) }
puts "never in a mention: #{silent.join(", ")}"
