module FCSHD
  def self.trim(string)
    string.gsub(/\s+/, " ").gsub(/^ | $/, "")
  end
end

require "fcshd/compiler"
require "fcshd/flex-home"
require "fcshd/logger"
require "fcshd/problem"
require "fcshd/server"
require "fcshd/source-location"
require "fcshd/transcript"
require "fcshd/transcript-item"
require "fcshd/transcript-parser"
require "fcshd/version"
