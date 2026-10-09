# frozen_string_literal: true

module Sake
  module Stdlib
    module_function

    # Threads run a block on a child interpreter (Interpreter#call_builtin); the block shares the
    # variables around it, as every Sake block does. Queue and Mutex are Ruby's. A socket is "Socket".
    def install_concurrency(reg)
      reg.define("Thread", :new, [], block: :required) do |&b|
        th = ::Thread.new { b.call }
        th.report_on_exception = false
        ThreadValue.new(th)
      end
      reg.define("Thread", :value, ["Thread"]) { |t| t.thread.value }
      # join(t, limit): t, or nil when the thread is still running after limit seconds (Ruby's).
      reg.define("Thread", :join, ["Thread"], optional: [%w[Integer Float Rational]]) { |t, limit = nil| t.thread.join(limit) && t }
      reg.define("Thread", :alive?, ["Thread"]) { |t| t.thread.alive? }
      # The running thread (the main program's, or one made by Thread.new): two values of the same thread are ==.
      reg.define("Thread", :current, []) { ThreadValue.new(::Thread.current) }
      reg.define("Mutex", :new, []) { ::Thread::Mutex.new }
      reg.define("Mutex", :synchronize, ["Mutex"], block: :required) { |m, &b| m.synchronize { b.call } }
      reg.define("Mutex", :lock, ["Mutex"]) { |m| ruby_error("ThreadError") { m.lock } }
      reg.define("Mutex", :unlock, ["Mutex"]) { |m| ruby_error("ThreadError") { m.unlock } }
      reg.define("Mutex", :try_lock, ["Mutex"], &:try_lock)
      reg.define("Mutex", :locked?, ["Mutex"], &:locked?)
      reg.define("Mutex", :owned?, ["Mutex"], &:owned?)
      reg.define("Queue", :new, []) { ::Thread::Queue.new }
      reg.define("Queue", :push, %w[Queue Any]) do |q, x|
        q.push(x)
      rescue ::ClosedQueueError
        raise Fail.new("IOError", "push to a closed Queue")
      end
      # pop(q[, timeout]): nil once the queue is closed and empty, or when nothing arrives within timeout seconds.
      reg.define("Queue", :pop, ["Queue"], optional: [%w[Integer Float Rational]]) { |q, timeout = nil| timeout ? q.pop(timeout: timeout) : q.pop }
      reg.define("Queue", :close, ["Queue"]) { |q| q.close && q }
      reg.define("Queue", :size, ["Queue"], &:size)
      reg.define("Queue", :empty?, ["Queue"], &:empty?)
      reg.define("Queue", :closed?, ["Queue"], &:closed?)
    end

    def install_net(reg)
      reg.define("TCPServer", :new, %w[String Integer]) { |host, port| net_error { require "socket"; ::TCPServer.new(host, port) } }
      reg.define("TCPServer", :accept, ["TCPServer"]) { |s| net_error { s.accept } }
      reg.define("TCPServer", :port, ["TCPServer"]) { |s| s.addr[1] }
      reg.define("TCPServer", :close, ["TCPServer"]) { |s| s.close.then { nil } }
      reg.define("Socket", :connect, %w[String Integer]) { |host, port| net_error { require "socket"; ::TCPSocket.new(host, port) } }
      reg.define("Socket", :gets, ["Socket"]) { |s| net_error { s.gets } }
      reg.define("Socket", :read, %w[Socket Integer]) { |s, n| net_error { nonneg(n) && s.read(n) } }
      reg.define("Socket", :write, %w[Socket String]) { |s, str| net_error { s.write(str) } }
      reg.define("Socket", :close_write, ["Socket"]) { |s| net_error { s.close_write.then { nil } } }
      reg.define("Socket", :close, ["Socket"]) { |s| s.close.then { nil } }
    end

    def ruby_error(kind)
      yield
    rescue ::ThreadError, ::ArgumentError => e
      raise Fail.new(kind, e.message)
    end

    def net_error
      yield
    rescue SystemCallError, IOError => e
      raise Fail.new("IOError", e.message)
    rescue StandardError => e
      raise unless e.class.name == "SocketError" # defined only once socket is loaded
      raise Fail.new("IOError", e.message)
    rescue LoadError, NotImplementedError => e
      raise Fail.new("IOError", "sockets are not available here (#{e.message})")
    end
  end
end
