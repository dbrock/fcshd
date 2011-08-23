module FCSHD
  class CompilerOutputWriter
    def initialize(output, basedir)
      @output = output
      @basedir = basedir
    end

    def write! subject
      @subject = subject
      yield
    end

    def write_uninterpreted_line! line
      @output.puts "mxmlc: #{line}"
    end

    def write_problem! problem
      location = problem.source_location.with_basedir(@basedir)
      for line in problem.message_lines do
        @output.puts "#{location}: #{line}"
      end
    end

    def relativize_filename(filename)
      filename.sub(/^#{Regexp.quote(@basedir)}/, "")
    end
  end
end
