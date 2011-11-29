module FCSHD
  class SourceLocation < Struct.new(:filename, :line_number)
    def to_s(basedir=nil)
      "#{relative_filename(basedir)}:#{line_number || 0}"
    end

    def relative_filename(basedir)
      if basedir
        filename.sub(/^#{Regexp.quote(basedir)}/, "")
      else
        filename
      end
    end
  end
end
