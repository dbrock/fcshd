module FCSHD
  class SourceLocation < Struct.new \
    :filename, :line_number, :column_number, :basedir

    def to_s
      relative_filename.tap do |result|
        result << ":#{line_number}" if line_number
      end
    end

    def relative_filename
      if basedir
        filename.sub(/^#{Regexp.quote(basedir)}/, "")
      else
        filename
      end
    end

    def with_basedir(new_basedir)
      dup.tap { |result| result.basedir = new_basedir }
    end

    def without_column_number
      dup.tap { |result| result.column_number = nil }
    end
  end
end
