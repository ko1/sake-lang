gem "activesupport", "8.1.3"
require "active_support"
require "active_support/core_ext/string/output_safety"
require "active_support/core_ext/object/blank"

# SafeBuffer, String#html_safe and ERB::Util (core_ext/string/output_safety, core_ext/erb/util)
buf = "<p>".html_safe
buf.concat("<script>alert(1)</script>")
buf.concat("<b>ok</b>".html_safe)
buf.concat(nil)
buf.safe_concat("</p>")
puts(buf)
p(buf.html_safe?, "x".html_safe?, 1.html_safe?, "x".html_safe?, buf.length)
both = "<i>".html_safe + "<u>"
p(both.to_str, both.html_safe?)
p(("<li>%s</li>".html_safe % "<x>").to_str, ("%s-%s".html_safe % ["<a>", "<b>".html_safe]).to_str)
p(("<a href=\"%{url}\">".html_safe % { url: "/?a=1&b=2" }).to_str, ("<hr>".html_safe * 2).to_str)
up = buf.upcase
p(up, buf.gsub("p>", "div>"))
copy = buf.dup
copy.upcase!
p(copy.html_safe?, buf.html_safe?)
copy.concat("<now escaped? no>")
puts(copy)
begin
  copy.safe_concat("x")
rescue ActiveSupport::SafeBuffer::SafeConcatError => e
  puts e.message
end
p((buf[0, 3] || "".html_safe).to_str, "  x ".html_safe.strip)
p(ERB::Util.html_escape("<a href='x'>&</a>").to_str, ERB::Util.h(buf).to_str, ERB::Util.h(12).to_str)
p(ERB::Util.html_escape_once("1 < 2 &amp; 3 &#x27; &foo").to_str, ERB::Util.json_escape("{\"x\":\"</script>&\"}"), ERB::Util.xml_name_escape("1 <bad> name"), ERB::Util.xml_name_escape("ok-name"))
