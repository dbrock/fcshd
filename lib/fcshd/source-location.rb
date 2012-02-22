require "pathname"

module FCSHD
  class SourceLocation < Struct.new(:filename, :line_number)
    def to_s(basedir=nil)
      "#{relative_filename(basedir)}:#{line_number || 0}"
    end

    def relative_filename(basedir)
      Pathname.new(filename).relative_path_from(Pathname.new(basedir))
    end
  end
end
