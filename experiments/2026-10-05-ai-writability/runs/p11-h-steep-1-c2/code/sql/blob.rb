# frozen_string_literal: true

module Sql
  # A BLOB value: a string of bytes. It is a hash key (eql?/hash) by its bytes.
  class Blob
    attr_reader :bytes

    def initialize(bytes)
      @bytes = bytes.b.freeze
    end

    # The blob of a run of hexadecimal digits, two per byte (the caller checked the digits).
    def self.from_hex(digits)
      new([digits].pack("H*"))
    end

    # Two uppercase hexadecimal digits per byte.
    def hex
      @bytes.each_byte.map { |byte| format("%02X", byte) }.join
    end

    # The bytes read as characters (spec 7.1).
    def text
      @bytes.dup.force_encoding(Encoding::UTF_8)
    end

    # Byte by byte as unsigned bytes; a prefix comes first. Returns -1, 0 or 1.
    def compare(other)
      @bytes <=> other.bytes || 0
    end

    def eql?(other)
      other.is_a?(Blob) && @bytes == other.bytes
    end

    def hash
      @bytes.hash
    end

    # The SQL literal; also what a result row prints.
    def inspect
      "X'#{hex}'"
    end
  end
end
