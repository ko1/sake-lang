module MiniSql
  # A BLOB value: a string of bytes. It is equal (and hashes) only to a Blob of the same bytes, so a TEXT with the
  # same bytes is a different value.
  class Blob
    attr_reader :data

    def initialize(data)
      @data = data.b
    end

    # The blob of these hexadecimal digits (an even number of them), two per byte.
    def self.from_hex(digits)
      new([digits].pack("H*"))
    end

    # The bytes read as characters (SPEC 7.1).
    def text
      @data.dup.force_encoding(Encoding::UTF_8)
    end

    # Two uppercase hexadecimal digits per byte.
    def hex
      @data.bytes.map { |byte| format("%02X", byte) }.join
    end

    def eql?(other)
      other.is_a?(Blob) && @data == other.data
    end

    def hash
      @data.hash
    end
  end
end
