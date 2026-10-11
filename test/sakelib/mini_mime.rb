require "mini_mime"

# one line per lookup: extension, content type, encoding, binary?
def show(info)
  if info
    p([info.extension, info.content_type, info.encoding, info.binary?])
  else
    p(nil)
  end
end

# by file name: the extension decides, case-insensitively as a fallback
show(MiniMime.lookup_by_filename("a.txt"))
show(MiniMime.lookup_by_filename("photo.JPG"))
show(MiniMime.lookup_by_filename("/path/to/archive.tar.gz"))
show(MiniMime.lookup_by_filename("index.html"))
show(MiniMime.lookup_by_filename("Makefile"))
show(MiniMime.lookup_by_filename("unknown.zzzz"))
show(MiniMime.lookup_by_filename(".bashrc"))

# by extension (without the dot)
show(MiniMime.lookup_by_extension("json"))
show(MiniMime.lookup_by_extension("PNG"))
show(MiniMime.lookup_by_extension("123"))
show(MiniMime.lookup_by_extension("zip"))
show(MiniMime.lookup_by_extension(".zip"))

# by content type: the extension usually given for it
show(MiniMime.lookup_by_content_type("text/plain"))
show(MiniMime.lookup_by_content_type("application/pdf"))
show(MiniMime.lookup_by_content_type("image/svg+xml"))
show(MiniMime.lookup_by_content_type("application/x-nope"))
show(MiniMime.lookup_by_content_type("TEXT/PLAIN"))

# the same lookup again comes from the cache
p(MiniMime.lookup_by_extension("json") == MiniMime.lookup_by_extension("json"))
p(MiniMime.lookup_by_extension("nope") == nil)

# an Info is indexable: 0 extension, 1 content type, 2 encoding
info = MiniMime.lookup_by_extension("css")

p([info[0], info[1], info[2], info[3]])
p(MiniMime::Info.new("ext  type/x  base64").binary?)
p(MiniMime::Info.new("ext  type/x  7bit").content_type)

# many extensions, in a table
"mp3 mp4 webm woff2 csv xml yaml md rb py js wasm ico".split(" ").each do |ext|
  i = MiniMime.lookup_by_extension(ext)
  puts("#{ext.ljust(6)} #{i ? i.content_type : "-"}")
end

# the db files are where Configuration says
p(File.basename(MiniMime::Configuration.ext_db_path))
p(File.basename(MiniMime::Configuration.content_type_db_path))
