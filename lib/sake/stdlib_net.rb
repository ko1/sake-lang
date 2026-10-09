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
      # kill(t): ends the thread where it is (its ensure clauses run); raise(t, message): a RuntimeError is raised in
      # it, where it is (Timeout.timeout stops a block with this).
      reg.define("Thread", :kill, ["Thread"]) { |t| t.thread.kill; t }
      reg.define("Thread", :raise, %w[Thread String]) { |t, msg| t.thread.raise(RunError.new("RuntimeError", msg, 0)); t }
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
      # connect(host, port[, timeout]): IOError when the connection is not made within timeout seconds.
      reg.define("Socket", :connect, %w[String Integer], optional: [%w[Integer Float Rational]]) do |host, port, timeout = nil|
        net_error { require "socket"; timeout ? ::TCPSocket.new(host, port, connect_timeout: timeout) : ::TCPSocket.new(host, port) }
      end
      # connect_ssl(host, port[, timeout]): a TLS connection (Ruby's OpenSSL::SSL::SSLSocket, verifying the peer).
      # The Socket operations read and write it; close closes the TCP connection too.
      reg.define("Socket", :connect_ssl, %w[String Integer], optional: [%w[Integer Float Rational]]) do |host, port, timeout = nil|
        net_error do
          require "socket"
          require "openssl"
          tcp = timeout ? ::TCPSocket.new(host, port, connect_timeout: timeout) : ::TCPSocket.new(host, port)
          ctx = ::OpenSSL::SSL::SSLContext.new
          ctx.set_params(verify_mode: ::OpenSSL::SSL::VERIFY_PEER)
          ssl = ::OpenSSL::SSL::SSLSocket.new(tcp, ctx)
          ssl.hostname = host
          ssl.sync_close = true
          ssl.connect
        end
      end
      # set_timeout(s, seconds): a read or write that waits longer raises IOError (Ruby's IO#timeout=).
      reg.define("Socket", :set_timeout, ["Socket", %w[Integer Float Rational Nil]]) { |s, secs| s.timeout = secs; s }
      reg.define("Socket", :gets, ["Socket"]) { |s| net_error { s.gets } }
      reg.define("Socket", :read, %w[Socket Integer]) { |s, n| net_error { nonneg(n) && s.read(n) } }
      reg.define("Socket", :write, %w[Socket String]) { |s, str| net_error { s.write(str) } }
      reg.define("Socket", :close_write, ["Socket"]) { |s| net_error { (s.respond_to?(:close_write) ? s : s.io).close_write.then { nil } } }
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
      raise unless %w[SocketError OpenSSL::SSL::SSLError].include?(e.class.name) # defined once their library is loaded
      raise Fail.new("IOError", e.message)
    rescue LoadError, NotImplementedError => e
      raise Fail.new("IOError", "sockets are not available here (#{e.message})")
    end
  end
end
