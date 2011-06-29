module FCSHD
  class Logger
    def initialize(output)
      @stderr = output
    end

    def log_raw(message)
      @stderr.puts message
    end

    def log(message)
      for line in message.lines
        log_raw "#{program_name}: #{line.chomp}"
      end
    end

    def program_name
      File.basename($0)
    end

    def error(message)
      for line in message.lines
        log "error: #{line.chomp}"
      end
    end

    def die(message)
      error message ; exit
    end

    def exit(code=1)
      Kernel.exit code
    end

    def format_command(command, output)
      ["$ #{command}", *output.lines].
        map { |line| "    #{line.chomp}" }.
        join("\n")
    end
  end
end
