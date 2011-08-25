module FCSHD
  class CompilerOutputWriter
    def initialize(output, basedir)
      @output = output
      @basedir = basedir
    end

    def write_uninterpreted_line! line
      @output.puts line
    end

    def write_problem! problem
      location = problem.source_location.with_basedir(@basedir)
      for line in problem.formatted_message_lines do
        @output.puts "#{location}: #{line}"
      end
    end
  end
end
