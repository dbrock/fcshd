module FCSHD
  class SourceLocation < Struct.new \
    :filename, :line_number, :column_number, :basedir

    def to_s
      "".tap do |result|
        result << relative_filename
        result << ":#{line_number || 0}"
        result << ":#{column_number}" if column_number
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
