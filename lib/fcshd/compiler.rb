module FCSHD
  class Compiler
    def initialize(fcsh_executable, logger)
      @fcsh_executable = fcsh_executable
      @logger = logger
    end

    def start!
      stop!
      @process = IO.popen("#@fcsh_executable 2>&1", "r+")
      read_until_prompt =~ /Version (\S+)/
      @logger.log "Started fcsh #{$1 || "(unknown version)"}."
    rescue PromptNotFound => error
      @logger.error "Could not find (fcsh) prompt:"
      @logger.error @logger.format_command(@fcsh, error.message)
      @logger.log "Please set $FLEX_HOME or $FCSH." if
        error.message.include? "command not found"
      @logger.exit
    end

    alias :restart! :start!

    def compile! command
      if @command_ids.include? command
        recompile! @command_ids[command]
      else
        compile_new! command
      end
    end

  private

    def stop!
      @process.close if @process
      @process = nil
      @command_ids = {}
    end

    def compile_new! command
      send_command! command
      read_until_prompt.tap do |output|
        case output
        when /^fcsh: Assigned (\d+) as the compile target id$/
          @command_ids[command] = $1
        else
          @logger.error "Could not determine compile target ID:"
          @logger.error @logger.format_command("(fcsh) #{command}", output)
        end
      end
    end

    def recompile! id
      send_command! "compile #{id}"
      read_until_prompt
    end

    def send_command! command
      @logger.log(command)
      @process.puts(command)
    end

    class PromptNotFound < Exception ; end

    def read_until_prompt
      result = ""
      result << @process.readpartial(256) until
        result.include? "\n(fcsh) "
      result.sub(/^.*\Z/, "")
    rescue EOFError
      raise PromptNotFound, result
    end
  end
end
