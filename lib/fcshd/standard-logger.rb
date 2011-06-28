module FCSHD
  class StandardLogger
    def log(message)
      for line in message.lines
        warn "#{program_name}: #{line.chomp}"
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
