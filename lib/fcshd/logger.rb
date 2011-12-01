module FCSHD
  class Logger
    def initialize(output)
      @output = output
    end

    def log(message)
      for line in message.lines
        @output.puts "#{File.basename($0)}: #{line.chomp}"
      end
    end

    def dump(output)
      @output.puts output.chomp
    end

    def error(message)
      for line in message.lines
        log "error: #{line.chomp}"
      end
    end

    def die(message)
      error message
      exit 1
    end
  end
end
