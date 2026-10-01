class Track
  attr_accessor :title, :artist, :secs, :prev, :next

  def initialize(title, artist, secs, prev, nxt)
    @title = title
    @artist = artist
    @secs = secs
    @prev = prev
    @next = nxt
  end

  def to_s = "#{@title} (#{@artist}, #{@secs / 60}:#{(@secs % 60).to_s.rjust(2, "0")})"
end

class Playlist
  attr_reader :name, :now, :count

  def initialize(name)
    @name = name
    @now = nil
    @count = 0
  end

  def add(title, artist, secs)
    t = Track.new(title, artist, secs, nil, nil)
    if @now.nil?
      t.prev = t
      t.next = t
      @now = t
    else
      last = @now.prev
      last.next = t
      t.prev = last
      t.next = @now
      @now.prev = t
    end
    @count += 1
    t
  end

  def each_from_now
    return unless @now
    t = @now
    @count.times do
      yield t
      t = t.next
    end
  end

  def skip(n)
    return nil unless @now
    if n >= 0
      n.times { @now = @now.next }
    else
      (-n).times { @now = @now.prev }
    end
    @now
  end

  def remove_current
    cur = @now
    return nil unless cur
    if @count == 1
      @now = nil
    else
      cur.prev.next = cur.next
      cur.next.prev = cur.prev
      @now = cur.next
    end
    @count -= 1
    cur
  end

  def move_current_after(title)
    target = nil
    each_from_now { |t| target ||= t if t.title == title }
    return false if target.nil? || @now.nil? || target.equal?(@now)
    moved = remove_current
    @count += 1
    after = target.next
    target.next = moved
    moved.prev = target
    moved.next = after
    after.prev = moved
    true
  end

  def total_secs
    s = 0
    each_from_now { |t| s += t.secs }
    s
  end

  def titles
    out = []
    each_from_now { |t| out << t.title }
    out.join(" | ")
  end
end

def play_for(pl, budget)
  played = []
  while budget > 0 && pl.now
    t = pl.now
    if t.secs > budget
      played << "#{t.title} (partial #{budget}s)"
      budget = 0
    else
      played << t.title
      budget -= t.secs
      pl.skip(1)
    end
  end
  played
end

pl = Playlist.new("road trip")
[
  ["Intro", "Aster", 95], ["Highway", "Bellows", 241], ["Neon Rain", "Cato", 187],
  ["Detour", "Aster", 302], ["Last Exit", "Duna", 158], ["Homecoming", "Bellows", 214]
].each { |title, artist, secs| pl.add(title, artist, secs) }

puts "#{pl.name}: #{pl.count} tracks, #{pl.total_secs / 60} min"
puts "order: #{pl.titles}"
puts "now: #{pl.now}"
puts "skip 2 -> #{pl.skip(2)}"
puts "skip -3 -> #{pl.skip(-3)}"
puts "skip 7 -> #{pl.skip(7)}"
puts "removed: #{pl.remove_current}; now #{pl.now}"
puts "order: #{pl.titles}"
puts "move current after Last Exit: #{pl.move_current_after("Last Exit")}"
puts "order: #{pl.titles}"
puts "move after Nowhere: #{pl.move_current_after("Nowhere")}"
puts "played in 10 min: #{play_for(pl, 600).join(", ")}"
by_artist = Hash.new(0)
pl.each_from_now { |t| by_artist[t.artist] += t.secs }
by_artist.sort_by { |_, s| -s }.each { |a, s| puts format("  %-8s %3ds", a, s) }
pl.remove_current while pl.count > 0
puts "emptied: now=#{pl.now.inspect} skip=#{pl.skip(1).inspect}"
