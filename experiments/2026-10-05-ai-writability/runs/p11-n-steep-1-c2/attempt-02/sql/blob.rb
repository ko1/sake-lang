# frozen_string_literal: true

module Sql
  # A BLOB value: a string of bytes. Equal (eql?) exactly when the bytes are, so it can be a hash key.
  class Blob
    attr_reader :bytes

    # bytes is copied into a binary (ASCII-8BIT) string.
    def initialize(bytes)
      @bytes = bytes.b
    end

    # Whether text is an even number of hexadecimal digits (the inside of a blob literal).
    def self.valid_hex?(text)
      text.match?(/\A(?:[0-9A-Fa-f]{2})*\z/)
    end

    # The blob a valid_hex? text spells.
    def self.from_hex(text)
      new([text].pack("H*"))
    end

    # Two uppercase hexadecimal digits per byte.
    def hex
      @bytes.each_byte.map { |byte| format("%02X", byte) }.join
    end

    # The bytes read as characters (spec 7.1).
    def text
      @bytes.dup.force_encoding("UTF-8")
    end

    def length
      @bytes.bytesize
    end

    # Unsigned bytewise; a prefix comes first.
    def <=>(other)
      @bytes <=> other.bytes
    end

    def eql?(other)
      other.is_a?(Blob) && @bytes == other.bytes
    end

    def hash
      @bytes.hash
    end

    # Also the label of a blob literal in an expression's signature.
    def inspect
      "X'#{hex}'"
    end
  end
end
