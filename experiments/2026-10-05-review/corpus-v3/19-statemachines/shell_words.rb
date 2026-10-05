class ShellSyntaxError < StandardError
  attr_reader :index

  def initialize(message, index)
    super(message)
    @index = index
  end
end

class Word
  attr_reader :kind, :text

  def initialize(kind, text)
    @kind = kind
    @text = text
  end

  def to_s = @kind == :op ? @text : @text.inspect
end

OPERATOR_CHARS = "|;&<>"

def expand_var(name, env) = env.fetch(name, "")

def split_words(line, env)
  words = []
  cur = +""
  in_word = false
  state = :normal
  var = +""
  resume = :normal
  i = 0
  chars = line.chars
  n = chars.size
  while i <= n
    c = chars[i]
    case state
    in :var
      if c && c.match?(/\w/)
        var << c
        i += 1
        next
      end
      cur << expand_var(var, env)
      var = +""
      state = resume
      next
    in :escape
      raise ShellSyntaxError.new("trailing backslash", i) if c.nil?
      cur << c
      in_word = true
      state = resume
    in :single
      raise ShellSyntaxError.new("unterminated single quote", i) if c.nil?
      if c == "'"
        state = :normal
      else
        cur << c
      end
    in :double
      raise ShellSyntaxError.new("unterminated double quote", i) if c.nil?
      if c == "\""
        state = :normal
      elsif c == "\\" && chars[i + 1] && "\"\\$".include?(chars[i + 1])
        resume = :double
        state = :escape
      elsif c == "$"
        resume = :double
        state = :var
      else
        cur << c
      end
    in :normal
      if c.nil? || c == " " || c == "\t"
        words << Word.new(:word, cur) if in_word
        cur = +""
        in_word = false
      elsif OPERATOR_CHARS.include?(c)
        words << Word.new(:word, cur) if in_word
        cur = +""
        in_word = false
        op = c
        nxt = chars[i + 1]
        if nxt && ["&&", "||", ">>"].include?(c + nxt)
          op = c + nxt
          i += 1
        end
        words << Word.new(:op, op)
      else
        in_word = true
        case c
        in "'" then state = :single
        in "\"" then state = :double
        in "\\"
          resume = :normal
          state = :escape
        in "$"
          resume = :normal
          state = :var
        else cur << c
        end
      end
    end
    i += 1
  end
  words
end

def pipeline_stages(words)
  stages = [[]]
  words.each do |w|
    if w.kind == :op && w.text == "|"
      stages << []
    else
      stages.last << w
    end
  end
  stages
end

env = { "HOME" => "/home/ann", "USER" => "ann", "EMPTY" => "" }
lines = [
  "echo hello   world",
  "ls -l $HOME/src | grep 'foo bar' > out.txt",
  "printf \"%s says \\\"hi\\\" in $HOME\" $USER && echo done",
  "a\\ b c\\\\d 'it''s' x$EMPTY\"\"y",
  "cat <in >>log; echo $UNSET.",
  "echo 'unterminated",
  "echo \"also",
  "trailing \\"
]
lines.each do |line|
  puts line
  begin
    words = split_words(line, env)
    puts "  => #{words.join(" ")}"
    stages = pipeline_stages(words)
    puts "  stages: #{stages.size}, ops: #{words.count { it.kind == :op }}" if stages.size > 1
  rescue ShellSyntaxError => e
    puts "  error at #{e.index}: #{e.message}"
  end
end
