class Keypad
  attr_reader :code, :state, :buffer, :failures, :lockout_until

  def initialize(code)
    @code = code
    @state = :locked
    @buffer = ""
    @failures = 0
    @lockout_until = 0
  end

  def press(now, key)
    if @state == :lockout
      return "ignored (locked out)" if now < @lockout_until
      @state = :locked
      @failures = 0
    end
    case @state
    in :locked | :entering
      on_entry_key(now, key)
    in :unlocked
      case key
      in "L"
        @state = :locked
        "relocked"
      in "C"
        @state = :changing
        @buffer = ""
        "enter new code"
      else "already open"
      end
    in :changing
      if key == "#"
        if @buffer.size < 4
          @buffer = ""
          "code too short"
        else
          @code = @buffer
          @buffer = ""
          @state = :unlocked
          "code changed"
        end
      elsif key == "*"
        @buffer = ""
        @state = :unlocked
        "change cancelled"
      elsif key.match?(/\A[0-9]\z/)
        @buffer += key
        "new digit"
      else
        "digits only"
      end
    end
  end

  def on_entry_key(now, key)
    if key == "*"
      @buffer = ""
      @state = :locked
      return "cleared"
    end
    if key != "#"
      return "bad key #{key}" unless key.match?(/\A[0-9]\z/)
      @buffer += key
      @state = :entering
      return "digit #{@buffer.size}"
    end
    attempt = @buffer
    @buffer = ""
    if attempt == @code
      @failures = 0
      @state = :unlocked
      "OPEN"
    else
      @failures += 1
      if @failures >= 3
        @state = :lockout
        @lockout_until = now + 10
        "wrong code, locked out until t=#{@lockout_until}"
      else
        @state = :locked
        "wrong code (#{@failures}/3)"
      end
    end
  end
end

def masked(s) = "*" * s.size

pad = Keypad.new("4711")
script = "47#*9999#1234#0000#55#4711#X4711#C12#9876#L4711#9876#"
now = 0
opened = 0
script.each_char do |key|
  now += 1
  now += 8 if key == "X"
  msg = pad.press(now, key)
  opened += 1 if msg == "OPEN"
  puts format("t=%-3d key=%s %-9s buf=%-5s %s", now, key, pad.state, masked(pad.buffer), msg)
end
puts "opened #{opened} times; final code length #{pad.code.size}"
