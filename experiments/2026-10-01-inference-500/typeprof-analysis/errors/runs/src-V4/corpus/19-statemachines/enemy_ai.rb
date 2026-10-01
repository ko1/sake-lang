class Vec
  attr_reader :x, :y

  def initialize(x, y)
    @x = x
    @y = y
  end

  def +(other) = Vec.new(@x + other.x, @y + other.y)
  def -(other) = Vec.new(@x - other.x, @y - other.y)
  def ==(other) = other.is_a?(Vec) && @x == other.x && @y == other.y
  def manhattan = @x.abs + @y.abs
  def sign = Vec.new(@x.clamp(-1, 1), @y.clamp(-1, 1))
  def to_s = "(#{@x},#{@y})"
end

SIGHT_RANGE = 5
ATTACK_RANGE = 1
FLEE_HP = 30

class Enemy
  attr_reader :name, :pos, :hp, :state, :patrol, :waypoint, :transitions

  def initialize(name, pos, patrol)
    @name = name
    @pos = pos
    @hp = 100
    @state = :patrol
    @patrol = patrol
    @waypoint = 0
    @transitions = 0
  end

  def step_toward(target)
    d = (target - @pos).sign
    d = Vec.new(d.x, 0) if d.x != 0
    @pos += d
  end

  def step_away(target)
    d = (@pos - target).sign
    d = Vec.new(1, 0) if d.manhattan == 0
    @pos += d
  end

  def next_state(player, player_hits)
    dist = (player - @pos).manhattan
    case @state
    in :dead then :dead
    in :patrol then dist <= SIGHT_RANGE ? :chase : :patrol
    in :chase
      if @hp <= FLEE_HP then :flee
      elsif dist <= ATTACK_RANGE then :attack
      elsif dist > SIGHT_RANGE + 2 then :patrol
      else :chase
      end
    in :attack
      if @hp <= 0 then :dead
      elsif @hp <= FLEE_HP then :flee
      elsif dist > ATTACK_RANGE then :chase
      else :attack
      end
    in :flee
      if @hp <= 0 then :dead
      elsif dist > SIGHT_RANGE + 3 then :recover
      else :flee
      end
    in :recover
      if dist <= SIGHT_RANGE then :flee
      elsif @hp >= 80 then :patrol
      else :recover
      end
    end
  end

  def act(player, player_hits)
    case @state
    in :patrol
      target = @patrol[@waypoint]
      if @pos == target
        @waypoint = (@waypoint + 1) % @patrol.size
      else
        step_toward(target)
      end
      "patrols to #{@pos}"
    in :chase
      step_toward(player)
      "chases to #{@pos}"
    in :attack
      @hp -= player_hits ? 25 : 5
      "attacks (hp #{@hp})"
    in :flee
      step_away(player)
      "flees to #{@pos}"
    in :recover
      @hp = [@hp + 15, 100].min
      "recovers (hp #{@hp})"
    in :dead then "is dead"
    end
  end

  def tick(player, player_hits)
    before = @state
    @state = next_state(player, player_hits)
    @transitions += 1 if before != @state
    act(player, player_hits)
  end
end

player_path = [
  [0, 0], [1, 0], [2, 0], [3, 0], [4, 1], [5, 1], [6, 2], [7, 2], [7, 2], [7, 2],
  [7, 2], [7, 2], [7, 2], [7, 2], [7, 2], [7, 2], [7, 2], [6, 2], [5, 2], [4, 2],
  [3, 2], [2, 2], [1, 2], [0, 2], [0, 3], [0, 4], [0, 5], [0, 6], [1, 6], [2, 6],
  [3, 7], [3, 7], [3, 7], [3, 7], [3, 7]
]
enemies = [
  Enemy.new("grunt", Vec.new(9, 2), [Vec.new(9, 2), Vec.new(9, 6)]),
  Enemy.new("scout", Vec.new(2, 8), [Vec.new(2, 8), Vec.new(8, 8), Vec.new(8, 9)])
]
player_path.each_with_index do |(px, py), t|
  player = Vec.new(px, py)
  hits = t % 3 != 0
  lines = enemies.map do |e|
    "#{e.name} #{e.tick(player, hits)} [#{e.state}]"
  end
  puts format("t=%02d player=%-6s %s", t, player.to_s, lines.join(" | "))
end
enemies.each do |e|
  puts "#{e.name}: hp=#{e.hp} state=#{e.state} pos=#{e.pos} transitions=#{e.transitions}"
end
