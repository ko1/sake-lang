module MiniSql
  # A BLOB value: a string of bytes. Two Blobs are the same value exactly when their bytes are.
  class Blob
    attr_reader :bytes

    # The Blob a string of hexadecimal digit pairs denotes (the lexer has checked it).
    def self.from_hex(digits)
      new([digits].pack("H*"))
    end

    def initialize(bytes)
      @bytes = bytes.b
    end

    # The bytes read as characters (the text form, SPEC 7.1).
    def text
      @bytes.dup.force_encoding(Encoding::UTF_8).scrub
    end

    # Two uppercase hexadecimal digits per byte.
    def hex
      @bytes.each_byte.map { |byte| format("%02X", byte) }.join
    end

    def ==(other)
      other.is_a?(Blob) && @bytes == other.bytes
    end

    def eql?(other)
      self == other
    end

    def hash
      @bytes.hash
    end
  end
end
