# frozen_string_literal: true

module Sql
  # Names are case-insensitive for ASCII letters only; `fold` is the key to compare and store them by.
  # Error messages use the spelling the statement wrote, so keep the original beside the folded key.
  def self.fold(name)
    name.downcase(:ascii)
  end
end
