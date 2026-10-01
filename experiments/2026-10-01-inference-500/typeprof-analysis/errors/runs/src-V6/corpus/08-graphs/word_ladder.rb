require "set"

def dictionary
  ("cold cord card ward warm word worm wore core care dare date gate game " \
   "came come cole hole hold bold bolt boat coat cost most mist list lost " \
   "lust last cast case cave gave give live life wife wire fire fine mine " \
   "mind wind kind king ring rink sink sing song long lung hung").split(" ")
end

def pattern(word, i) = "#{word[0...i]}_#{word[i + 1..]}"

def buckets(words)
  index = {}
  words.each do |w|
    w.size.times do |i|
      (index[pattern(w, i)] ||= []) << w
    end
  end
  index
end

def ladder(index, from, to)
  return [from] if from == to
  prev = { from => nil }
  queue = [from]
  until queue.empty?
    word = queue.shift
    word.size.times do |i|
      index.fetch(pattern(word, i), []).each do |nb|
        next if prev.key?(nb)
        prev[nb] = word
        if nb == to
          path = [nb]
          cur = word
          while cur
            path.unshift(cur)
            cur = prev[cur]
          end
          return path
        end
        queue << nb
      end
    end
  end
  nil
end

def reachable_count(index, from)
  seen = Set[from]
  frontier = [from]
  depth = 0
  until frontier.empty?
    nxt = []
    frontier.each do |word|
      word.size.times do |i|
        index.fetch(pattern(word, i), []).each do |nb|
          nxt << nb if seen.add?(nb)
        end
      end
    end
    depth += 1 unless nxt.empty?
    frontier = nxt
  end
  [seen.size, depth]
end

words = dictionary
index = buckets(words)
busiest = index.max_by { |k, ws| ws.size }
puts "#{words.size} words, #{index.size} patterns; busiest #{busiest[0]} (#{busiest[1].size})"

[["cold", "warm"], ["cost", "fire"], ["king", "hung"], ["game", "lost"],
 ["mind", "boat"], ["cold", "cold"], ["jazz", "cold"]].each do |from, to|
  path = ladder(index, from, to)
  if path
    puts "#{from} -> #{to}: #{path.size - 1} steps: #{path.join(" > ")}"
  else
    puts "#{from} -> #{to}: impossible"
  end
end

["cold", "king"].each do |w|
  count, depth = reachable_count(index, w)
  puts "from #{w}: #{count} words reachable, farthest #{depth} steps"
end
