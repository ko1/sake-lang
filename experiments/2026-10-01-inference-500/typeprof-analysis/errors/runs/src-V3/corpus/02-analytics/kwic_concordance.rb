require "set"

def text
  "The river runs past the old mill. Children play by the river in summer. " +
  "In winter the river freezes and the mill stands silent. " +
  "The miller says the river gives and the river takes. " +
  "Nobody remembers when the mill last ground any grain."
end

def stopwords = Set["the", "and", "in", "by", "any", "when", "past"]

def sentences(t)
  t.split(/(?<=\.)\s+/).map do |s|
    s.downcase.split(/[^a-z]+/).reject(&:empty?)
  end
end

def build_concordance(sents)
  conc = {}
  sents.each_with_index do |words, si|
    words.each_with_index do |w, wi|
      (conc[w] ||= []) << [si, wi]
    end
  end
  conc
end

def context_line(words, wi, width)
  from = [wi - width, 0].max
  left = words[from...wi].join(" ")
  right = words.drop(wi + 1).take(width).join(" ")
  format("%28s [%s] %s", left, words[wi], right)
end

def collocates(sents, conc, keyword, span)
  counts = Hash.new(0)
  occurrences = conc[keyword]
  return counts unless occurrences
  occurrences.each do |si, wi|
    words = sents[si]
    ((wi - span)..(wi + span)).each do |j|
      next if j < 0 || j == wi
      w = words[j]
      next if w.nil? || w == keyword || stopwords.include?(w)
      counts[w] += 1
    end
  end
  counts
end

sents = sentences(text)
conc = build_concordance(sents)
puts "sentences: #{sents.size}, vocabulary: #{conc.size}"

["river", "mill", "winter", "boat"].each do |kw|
  occ = conc[kw]
  if occ.nil?
    puts "== #{kw}: not found =="
    next
  end
  puts "== #{kw} (#{occ.size}) =="
  occ.each do |si, wi|
    puts "#{si + 1}:#{(wi + 1).to_s.ljust(2)} #{context_line(sents[si], wi, 4)}"
  end
end

coll = collocates(sents, conc, "river", 3)
ranked = coll.to_a.sort_by { |w, n| [-n, w] }
puts "collocates of river: " + ranked.take(5).map { |w, n| "#{w}(#{n})" }.join(", ")

spread = conc.transform_values { |occ| occ.map(&:first).uniq.size }
wide = spread.select { |_, n| n >= 3 }.keys.sort
puts "in 3+ sentences: #{wide.join(", ")}"
firsts = conc.map { |w, occ| [w, occ[0]] }
late = firsts.select do |w, (si, _)|
  si >= 3 && !stopwords.include?(w)
end
puts "first seen in sentence 4+: #{late.map(&:first).sort.join(", ")}"
