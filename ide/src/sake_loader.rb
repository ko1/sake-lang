# Loads Sake from the sources the IDE bundles ($sake_sources: absolute path => source), in place of files.
$sake_loaded = {}
Dir.mkdir("/sake") unless Dir.exist?("/sake")
Dir.mkdir("/sake/sakelib") unless Dir.exist?("/sake/sakelib")
$sake_sources.each { |path, src| File.write(path, src) if path.end_with?(".sake") }
module Kernel
  def require_relative(path)
    base = File.dirname(caller_locations(1, 1).first.path)
    full = File.expand_path(path.end_with?(".rb") ? path : "#{path}.rb", base)
    src = $sake_sources[full] or return require(full) # a library file (prism requires its own parts)
    return false if $sake_loaded[full]
    $sake_loaded[full] = true
    TOPLEVEL_BINDING.eval(src, full, 1)
    true
  end
  private :require_relative
end
