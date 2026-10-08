# frozen_string_literal: true

module Sql
  # A BLOB value: immutable bytes. eql?/hash make equal bytes the same hash key (GROUP BY, DISTINCT).
  class Blob
    HEX_DIGITS = /\A(?:[0-9A-Fa-f]{2})*\z/

    attr_reader :bytes

    # The Blob of a run of hex digits (two per byte, any case), or nil when it is not one.
    def self.from_hex(digits)
      return nil unless digits.match?(HEX_DIGITS)

      new([digits].pack("H*"))
    end

    # The Blob of the bytes of a string.
    def initialize(bytes)
      @bytes = bytes.b.freeze
    end

    def size
      @bytes.bytesize
    end

    # Uppercase hex, two digits per byte.
    def hex
      @bytes.unpack1("H*").to_s.upcase
    end

    # The bytes read as characters (spec 7.1).
    def text
      @bytes.dup.force_encoding(Encoding::UTF_8)
    end

    # Unsigned bytewise order; a prefix comes first.
    def <=>(other)
      @bytes <=> other.bytes
    end

    def eql?(other)
      other.is_a?(Blob) && @bytes == other.bytes
    end

    alias == eql?

    def hash
      @bytes.hash
    end

    def inspect
      "X'#{hex}'"
    end
  end
end
