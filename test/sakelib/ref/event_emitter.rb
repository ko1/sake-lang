# Reference implementation for test/sakelib/event_emitter.rb: Node's EventEmitter in plain Ruby with
# snake_case names. A listener is anything that responds to call (a block, a Proc, an object).

class EventEmitter
  def initialize
    @handlers = {}
  end

  def on(event, listener = nil, &block) = add(event, listener || block, false, false)
  alias add_listener on
  def once(event, listener = nil, &block) = add(event, listener || block, true, false)
  def prepend_listener(event, listener = nil, &block) = add(event, listener || block, false, true)
  def prepend_once_listener(event, listener = nil, &block) = add(event, listener || block, true, true)

  # Removes the most recently added listener == to the given one, as Node does.
  def off(event, listener)
    list = @handlers[event]
    return self unless list
    i = list.rindex { |l, _| l == listener }
    list.delete_at(i) if i
    @handlers.delete(event) if list.empty?
    self
  end
  alias remove_listener off

  def remove_all_listeners(event = nil)
    event.nil? ? @handlers.clear : @handlers.delete(event)
    self
  end

  def emit(event, *args)
    list = @handlers[event]
    if list.nil? || list.empty?
      raise "Unhandled error. (#{args[0].inspect})" if event == :error
      return false
    end
    current = list.dup
    current.each { |l, once| off(event, l) if once }
    current.each { |l, _| l.call(*args) }
    true
  end

  def listener_count(event) = @handlers[event]&.size || 0
  def listeners(event) = (@handlers[event] || []).map(&:first)
  def event_names = @handlers.keys

  private

  def add(event, listener, once, prepend)
    raise ArgumentError, "no listener" unless listener.respond_to?(:call)
    list = (@handlers[event] ||= [])
    prepend ? list.unshift([listener, once]) : list.push([listener, once])
    self
  end
end
