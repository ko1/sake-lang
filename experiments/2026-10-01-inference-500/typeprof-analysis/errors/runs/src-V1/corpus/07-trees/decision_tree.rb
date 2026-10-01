class Leaf
  attr_reader :label, :size

  def initialize(label, size)
    @label = label
    @size = size
  end
end

class Split
  attr_reader :attr, :branches, :majority

  def initialize(attr, branches, majority)
    @attr = attr
    @branches = branches
    @majority = majority
  end
end

def entropy(rows, target)
  n = rows.size.to_f
  rows.map { |r| r[target] }.tally.values.sum do |c|
    p = c / n
    0.0 - p * Math.log2(p)
  end
end

def majority(rows, target)
  counts = rows.map { |r| r[target] }.tally
  counts.keys.sort.max_by { |k| counts[k] }
end

def gain(rows, attr, target)
  base = entropy(rows, target)
  rest = rows.group_by { |r| r[attr] }.values.sum { |g| g.size * entropy(g, target) / rows.size }
  base - rest
end

def train(rows, attrs, target, depth, max_depth)
  labels = rows.map { |r| r[target] }.uniq
  return Leaf.new(labels.first, rows.size) if labels.size == 1
  return Leaf.new(majority(rows, target), rows.size) if attrs.empty? || depth == max_depth
  best, best_gain = attrs.map { |a| [a, gain(rows, a, target)] }.max_by { |_a, g| g }
  return Leaf.new(majority(rows, target), rows.size) if best_gain < 0.001
  remaining = attrs - [best]
  groups = rows.group_by { |r| r[best] }
  branches = groups.keys.sort.to_h { |value| [value, train(groups[value], remaining, target, depth + 1, max_depth)] }
  Split.new(best, branches, majority(rows, target))
end

def classify(node, row)
  case node
  when Leaf then node.label
  when Split
    child = node.branches[row[node.attr]]
    child.nil? ? node.majority : classify(child, row)
  end
end

def show(node, indent)
  case node
  when Leaf then puts "#{indent}=> #{node.label} (#{node.size})"
  when Split
    node.branches.each do |value, child|
      if child.is_a?(Leaf)
        puts "#{indent}#{node.attr} = #{value} => #{child.label} (#{child.size})"
      else
        puts "#{indent}#{node.attr} = #{value}:"
        show(child, indent + "  ")
      end
    end
  end
end

def count_nodes(node)
  case node
  when Leaf then [1, 1]
  when Split
    node.branches.values.map { |c| count_nodes(c) }.reduce([1, 0]) { |(t, l), (t2, l2)| [t + t2, l + l2] }
  end
end

def load(text)
  header, *lines = text.strip.lines.map { |l| l.strip.split(",") }
  lines.map { |values| header.zip(values).to_h }
end

training = load(<<~CSV)
  outlook,temp,humidity,wind,play
  sunny,hot,high,weak,no
  sunny,hot,high,strong,no
  overcast,hot,high,weak,yes
  rain,mild,high,weak,yes
  rain,cool,normal,weak,yes
  rain,cool,normal,strong,no
  overcast,cool,normal,strong,yes
  sunny,mild,high,weak,no
  sunny,cool,normal,weak,yes
  rain,mild,normal,weak,yes
  sunny,mild,normal,strong,yes
  overcast,mild,high,strong,yes
  overcast,hot,normal,weak,yes
  rain,mild,high,strong,no
CSV
attrs = %w[outlook temp humidity wind]
puts format("entropy(play) = %.4f", entropy(training, "play"))
attrs.each { |a| puts format("  gain(%-8s) = %.4f", a, gain(training, a, "play")) }

[1, 3].each do |max_depth|
  tree = train(training, attrs, "play", 0, max_depth)
  total, leaves = count_nodes(tree)
  puts "-- max depth #{max_depth}: #{total} nodes, #{leaves} leaves --"
  show(tree, "  ")
  correct = training.count { |r| classify(tree, r) == r["play"] }
  puts format("  training accuracy: %d/%d (%.1f%%)", correct, training.size, 100.0 * correct / training.size)
end

tree = train(training, attrs, "play", 0, 10)
tests = load(<<~CSV)
  outlook,temp,humidity,wind
  sunny,cool,high,strong
  overcast,mild,normal,weak
  rain,hot,normal,strong
  foggy,mild,high,weak
CSV
tests.each do |r|
  puts "#{attrs.map { |a| r[a] }.join("/")} -> #{classify(tree, r)}"
end
