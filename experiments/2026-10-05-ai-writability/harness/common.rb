# frozen_string_literal: true

require "open3"
require "json"
require "timeout"

module AW
  ROOT = File.expand_path("../../..", __dir__)          # the sake repository
  EXP = File.expand_path("..", __dir__)                 # this experiment
  SAKE = File.join(ROOT, "bin/sake")
  TIMEOUT = 20 # seconds per test case (the Sake interpreter is slow)

  module_function

  # [stdout, stderr, status or :timeout]
  def run(cmd, input)
    out = err = +""
    st = nil
    Open3.popen3(*cmd) do |i, o, e, t|
      i.write(input)
      i.close
      ro = Thread.new { o.read }
      re = Thread.new { e.read }
      unless t.join(TIMEOUT)
        Process.kill("KILL", t.pid)
        t.join
        st = :timeout
      end
      out = ro.value
      err = re.value
      st ||= t.value.exitstatus
    end
    [out, err, st]
  end

  def lang_of(file) = File.extname(file) == ".sake" ? "sake" : "ruby"

  def run_cmd(file, strict) = lang_of(file) == "sake" ? [SAKE, "--strict=#{strict}", file] : ["ruby", file]

  def check_cmd(file, strict) = lang_of(file) == "sake" ? [SAKE, "--strict=#{strict}", "-c", file] : ["ruby", "-wc", file]

  def cases(task_dir, kind)
    Dir[File.join(task_dir, kind, "*.in")].sort.map { |i| [File.basename(i, ".in"), File.read(i), File.read(i.sub(/\.in\z/, ".out"))] }
  end

  # Runs file on every case; [{name, ok, status, got, want, err}]
  def test(file, task_dir, kind, strict)
    cases(task_dir, kind).map do |name, input, want|
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      got, err, st = run(run_cmd(file, strict), input)
      sec = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0 # wall time of the whole process (start-up included)
      { name:, ok: st == 0 && got == want, status: st, got:, want:, err:, sec: }
    end
  end
end
