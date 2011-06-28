module FCSHD
  class Compiler
    def initialize(fcsh_executable, logger)
      @fcsh_executable = fcsh_executable
      @logger = logger
    end

    def start!
      stop!
      @process = IO.popen("#@fcsh_executable 2>&1", "r+")
      read_until_prompt! =~ /Version (\S+)/
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
      if @commands.include? command
        recompile! @commands[command]
      else
        compile_new! command
      end
    end

  private

    def stop!
      @process.close if @process
      @process = nil
      @commands = {}  # Maps commands to compilation IDs.
      @output = ""    # Holds output from the compiler.
    end

    def compile_new! command
      @logger.log "Compiling: #{command}"
      @process.puts(command)
      read_until_prompt!.tap do |output|
        case output
        when /^fcsh: Assigned (\d+) as the compile target id/
          @commands[command] = $1
        else
          @logger.error "Could not determine compile target ID:"
          @logger.error @logger.format_command("(fcsh) #{command}", output)
        end
      end
    end

    def recompile! id
      @logger.log "Recompiling: ##{id}"
      @process.puts("compile #{id}")
      read_until_prompt!
    end

    class PromptNotFound < Exception ; end

    def read_until_prompt!
      result = ""
      result << read! until result.include? "\n(fcsh) "
      result.sub(/^.*\Z/, "")
    rescue EOFError
      raise PromptNotFound, result
    end

    def read!
      @process.readpartial(256)
    end
  end
end
