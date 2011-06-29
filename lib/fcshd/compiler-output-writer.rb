module FCSHC
  class CompilerOutputWriter
    def initialize(output, basedir)
      @output = output
      @basedir = basedir
    end

    def write! subject
      @subject = subject
      start_writing!
      yield
      finish_writing!
    end

    def start_writing!
      if @subject.nothing_to_do?
        @output.puts "fcshc: Nothing to do."
      end
    end

    def write_uninterpreted_line! line
      @output.puts "mxmlc: #{chunk}"
    end

    def write_problem! problem
      location = problem.source_location.with_basedir(@basedir)
      for line in problem.message_lines do
        @output.puts "#{location}: #{message}"
      end
    end

    def relativize_filename(filename)
      filename.sub(/^#{Regexp.quote(@basedir)}/, "")
    end
  end
end
