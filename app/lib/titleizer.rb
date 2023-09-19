# Provides methods for manipulating strings
module Titleizer
  # Strips space-like characters (including "non-breaking spaces") from a string
  def self.super_strip(string)
    string&.remove(/\A[[:space:]]+|[[:space:]]+\z/, '')
  end
end
