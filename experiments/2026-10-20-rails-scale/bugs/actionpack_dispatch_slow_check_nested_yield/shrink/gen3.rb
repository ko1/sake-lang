# gen3.rb B K U REC WRAP (REC=0: send_ calls a non-recursive draw; WRAP=0: apply's branches call send_ directly): `resources` -> apply (B branches, each passing { yield } on) -> send_ (K call sites) -> resources
b, k, u, rec, wr = ARGV.map(&:to_i)
branches = (1..b).map { |i| <<~B }.join
  if @mode == #{i}
    @mode = 0
    #{wr == 1 ? "wrap(m) { send_(m, name, kind) { yield } }" : "send_(m, name, kind) { yield }"}
    return true
  end
B
sends = (1..k).map { |i| "  #{i == 1 ? "if" : "elsif"} kind == #{i}\n    #{rec == 1 ? "resources" : "draw"}(m, name, kind) { yield }\n" }.join + "  else\n    #{rec == 1 ? "resources" : "draw"}(m, name, 0) { yield }\n  end\n"
puts <<~S
  class Mapper
    attr_accessor depth, mode, routes
    def wrap(m)
      old = @depth
      @depth = old + 1
      begin
        yield
      ensure
        @depth = old
      end
    end
    def apply(m, name, kind)
  #{branches.gsub(/^/, "    ")}
      false
    end
    def send_(m, name, kind)
  #{sends.gsub(/^/, "    ")}
    end
    def draw(m, name, kind)
      wrap(m) do
        yield
        route(m, name)
      end
    end
    def route(m, name) = Array.push(@routes, "\#{@depth}:\#{name}")
    def resources(m, name, kind)
      return nil if apply(m, name, kind) { yield }
      wrap(m) do
        wrap(m) do
          yield
          route(m, name)
        end
      end
      nil
    end
  end
  m = Mapper.new(0, 1, String[])
  #{(1..u).map { |i| "  " * (i - 1) + "Mapper.resources(m, \"r#{i}\", #{i % 3}) do" }.join("\n")}
  #{"  " * u}Mapper.route(m, "leaf")
  #{(1..u).to_a.reverse.map { |i| "  " * (i - 1) + "end" }.join("\n")}
  p(Mapper.routes(m))
S
