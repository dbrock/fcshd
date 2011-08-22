module FCSHD
  class Compiler
    FCSH_EXECUTABLE = ENV["FCSH"] ||
      if flex_home = ENV["FLEX_HOME"]
        File.join(flex_home, "bin", "fcsh")
      else
        "fcsh"
      end

    def initialize(logger)
      @logger = logger
      @output_buffer = ""
    end

    def start!
      start_fcsh_process!
      parse_fcsh_boilerplate!
      @logger.log "Started Flex #@flex_version compiler shell."
    rescue PromptNotFound => error
      @logger.error "Could not find (fcsh) prompt:"
      @logger.error @logger.format_command(FCSH_EXECUTABLE, error.message)
      @logger.log "Please set $FLEX_HOME or $FCSH." if
        error.message.include? "command not found"
      @logger.exit
    end

    def compile! command
      if @command_ids.include? command
        recompile! @command_ids[command]
      else
        compile_new! command
      end

      @output_lines
    end

  private

    def start_fcsh_process!
      stop_fcsh_process!
      @fcsh_process = IO.popen("#{FCSH_EXECUTABLE} 2>&1", "r+")
      read_fcsh_output!
    end

    def stop_fcsh_process!
      @fcsh_process.close if @fcsh_process
      @fcsh_process = nil
      @command_ids = {}
    end

    def parse_fcsh_boilerplate!
      case @output
      when /Version (\S+)/
        @flex_version = $1
      else
        @flex_version = "(unknown version)"
      end
    end

    def compile_new! command
      send_fcsh_command! command
      parse_compilation_output!
    ensure
      unless @command_ids[command]
        @logger.error "Could not determine compilation ID:"
        @logger.error @logger.format_command("(fcsh) #{command}", @output)
      end
    end

    def recompile! id
      send_fcsh_command! "compile #{id}"
      parse_compilation_output!
    end

    def parse_compilation_output!
      for line in @output.lines
        case line
        when /^fcsh: Assigned (\d+) as the compile target id$/
          @command_ids[command] = $1
        when /^fcsh: /
          @logger.log_raw(line)
          @output_lines << line
        else
          @output_lines << line
        end
      end
    end

    def send_fcsh_command! command
      @logger.log(command)
      @fcsh_process.puts(command)
      read_fcsh_output!
    end

    FCSH_PROMPT = "\n(fcsh) "
    class PromptNotFound < Exception ; end

    def read_fcsh_output!
      @output_buffer << @fcsh_process.readpartial(256) until
        @output_buffer.include? FCSH_PROMPT
      @output, @output_buffer =
        @output_buffer.split(FCSH_PROMPT, 2)
      @output_lines = []
    rescue EOFError
      raise PromptNotFound, @output_buffer
    end
  end
end
