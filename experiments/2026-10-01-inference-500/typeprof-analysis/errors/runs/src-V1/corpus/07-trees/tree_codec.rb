class TNode
  attr_accessor :val, :left, :right

  def initialize(val, left, right)
    @val = val
    @left = left
    @right = right
  end
end

class DecodeError < StandardError
  attr_reader :token

  def initialize(message, token)
    super(message)
    @token = token
  end
end

def make_node(tok)
  return nil if tok == "null" || tok == "#"
  raise DecodeError.new("bad token #{tok.inspect}", tok) unless tok.match?(/\A-?\d+\z/)
  TNode.new(tok.to_i, nil, nil)
end

# "[1,2,3,null,5]" level order, as in many puzzle sites
def from_level(text)
  body = text.strip.delete_prefix("[").delete_suffix("]")
  return nil if body.strip == ""
  toks = body.split(",").map(&:strip)
  root = make_node(toks.shift)
  queue = [root]
  until queue.empty? || toks.empty?
    node = queue.shift
    next if node.nil?
    node.left = make_node(toks.shift)
    queue << node.left
    next if toks.empty?
    node.right = make_node(toks.shift)
    queue << node.right
  end
  root
end

def to_level(root)
  out = []
  queue = [root]
  until queue.empty?
    node = queue.shift
    if node.nil?
      out << "null"
    else
      out << node.val.to_s
      queue.push(node.left, node.right)
    end
  end
  out.pop while out.last == "null"
  "[#{out.join(",")}]"
end

def to_preorder(node, out)
  if node.nil?
    out << "#"
  else
    out << node.val.to_s
    to_preorder(node.left, out)
    to_preorder(node.right, out)
  end
  out
end

def from_preorder(toks)
  tok = toks.shift
  raise DecodeError.new("unexpected end of input", "") if tok.nil?
  node = make_node(tok)
  return nil if node.nil?
  node.left = from_preorder(toks)
  node.right = from_preorder(toks)
  node
end

def decode_preorder(text)
  toks = text.split(" ")
  root = from_preorder(toks)
  raise DecodeError.new("#{toks.size} extra token(s)", toks.first) unless toks.empty?
  root
end

def same?(a, b)
  return a.equal?(b) if a.nil? || b.nil?
  a.val == b.val && same?(a.left, b.left) && same?(a.right, b.right)
end

def mirror(node)
  return nil if node.nil?
  TNode.new(node.val, mirror(node.right), mirror(node.left))
end

def symmetric?(root) = root.nil? || same?(root.left, mirror(root.right))

# returns [height, diameter in edges, best downward path sum, best path sum anywhere]
def measure(node)
  return [0, 0, 0, nil] if node.nil?
  lh, ld, ldown, lbest = measure(node.left)
  rh, rd, rdown, rbest = measure(node.right)
  gl = [ldown, 0].max
  gr = [rdown, 0].max
  best = [lbest, rbest, node.val + gl + gr].compact.max
  [1 + [lh, rh].max, [ld, rd, lh + rh].max, node.val + [gl, gr].max, best]
end

inputs = ["[1,2,3,null,5]", "[1,2,2,3,4,4,3]", "[-10,9,20,null,null,15,7]", "[5,4,8,11,null,13,4,7,2,null,null,null,1]",
          "[]", "[2,-1]", "[1,2,x]"]
inputs.each do |text|
  root = from_level(text)
  pre = to_preorder(root, []).join(" ")
  back = decode_preorder(pre)
  h, diam, _down, best = measure(root)
  puts text
  puts "  preorder: #{pre}"
  puts "  level again: #{to_level(back)}, round trip #{same?(root, back) ? "ok" : "FAILED"}"
  puts "  mirror: #{to_level(mirror(root))}, symmetric: #{symmetric?(root)}"
  puts "  height #{h}, diameter #{diam}, max path sum #{best.nil? ? "-" : best}"
rescue DecodeError => e
  puts "#{text}: decode error: #{e.message}"
end

["1 2 # # 3 # #", "1 2 # #", "1 # # 4"].each do |pre|
  puts "#{pre} -> #{to_level(decode_preorder(pre))}"
rescue DecodeError => e
  puts "#{pre} -> decode error: #{e.message} (token #{e.token.inspect})"
end
