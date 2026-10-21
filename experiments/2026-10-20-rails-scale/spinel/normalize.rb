# Normalizes a walk.sh output for a markup-level diff: drops Rails' development-mode
# <!-- BEGIN/END app/views/... --> comments, sorts each tag's attributes, drops the "/" of a void tag,
# and drops lines with nothing after the "  |" body prefix. What remains differs in content, not spelling.
# ruby normalize.rb WALK_OUT > normalized
text = File.read(ARGV.fetch(0))
text = text.gsub(%r{<!-- BEGIN app/views/[^\n]*\n  \| -->}, "").gsub(%r{<!-- END app/views/[^\n]*?-->}, "")
tag = /<([a-zA-Z][\w-]*)((?:\s+[\w:-]+(?:="[^"]*")?)*)\s*\/?>/
text.each_line do |l|
  l = l.rstrip.gsub(tag) do
    name, attrs = $1, $2.scan(/[\w:-]+(?:="[^"]*")?/).sort
    "<#{name}#{attrs.map { " #{_1}" }.join}>"
  end
  next if l.empty? || l == "  |"
  puts l
end
