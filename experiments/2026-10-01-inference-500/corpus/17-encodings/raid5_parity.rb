# RAID-5 style striping with rotating XOR parity: write a message across four disks,
# lose one disk, rebuild it from the others, and detect a silently corrupted block.

class Disk
  attr_accessor :name, :blocks, :failed

  def initialize(name, blocks, failed)
    @name = name
    @blocks = blocks
    @failed = failed
  end
end

BLOCK_SIZE = 4

def xor_blocks(a, b) = a.each_with_index.map { |x, i| x ^ b[i] }

def zero_block = Array.new(BLOCK_SIZE, 0)

def parity_disk(stripe, disks) = (disks - 1) - stripe % disks

def write_array(data, disks)
  array = (0...disks).map { |i| Disk.new("disk#{i}", [], false) }
  chunks = data.bytes.each_slice(BLOCK_SIZE).map { |c| c + [0] * (BLOCK_SIZE - c.size) }
  per_stripe = disks - 1
  stripes = (chunks.size + per_stripe - 1) / per_stripe
  stripes.times do |s|
    data_blocks = (0...per_stripe).map { |j| chunks[s * per_stripe + j] || zero_block }
    parity = data_blocks.reduce(zero_block) { |acc, b| xor_blocks(acc, b) }
    p_disk = parity_disk(s, disks)
    k = 0
    array.each_with_index do |d, i|
      if i == p_disk
        d.blocks << parity
      else
        d.blocks << data_blocks[k]
        k += 1
      end
    end
  end
  array
end

def read_data(array)
  disks = array.size
  stripes = array.fetch(0).blocks.size
  bytes = []
  stripes.times do |s|
    p_disk = parity_disk(s, disks)
    array.each_with_index do |d, i|
      next if i == p_disk
      raise IOError, "#{d.name} has failed" if d.failed
      bytes.concat(d.blocks.fetch(s))
    end
  end
  bytes.reject(&:zero?).map(&:chr).join
end

def rebuild(array, lost)
  survivors = array.reject(&:failed)
  stripes = survivors.fetch(0).blocks.size
  lost.blocks = (0...stripes).map do |s|
    survivors.reduce(zero_block) { |acc, d| xor_blocks(acc, d.blocks.fetch(s)) }
  end
  lost.failed = false
  stripes
end

def scrub(array)
  stripes = array.fetch(0).blocks.size
  (0...stripes).select do |s|
    array.reduce(zero_block) { |acc, d| xor_blocks(acc, d.blocks.fetch(s)) }.any? { |x| x != 0 }
  end
end

def show(array)
  array.each do |d|
    cells = d.blocks.map { |b| b.map { |x| format("%02x", x) }.join }
    puts format("  %-6s %s%s", d.name, cells.join(" "), d.failed ? "  (FAILED)" : "")
  end
end

message = "Parity lets one disk die quietly."
array = write_array(message, 4)
show(array)
puts "read: #{read_data(array)}"
puts "scrub: #{scrub(array).size} inconsistent stripes"

victim = array.fetch(2)
victim.failed = true
begin
  read_data(array)
rescue IOError => e
  puts "degraded read: #{e.message}"
end
n = rebuild(array, victim)
puts "rebuilt #{victim.name}: #{n} stripes"
puts "read: #{read_data(array)}"

blk = array.fetch(1).blocks.fetch(1)
blk[2] ^= 0x20
bad = scrub(array)
puts "after bit rot, scrub flags stripes #{bad.inspect}"
puts "read: #{read_data(array)}"
