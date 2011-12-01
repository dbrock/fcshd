module FCSHD
  class Compiler
    def initialize(logger)
      @logger = logger
      @output_buffer = ""
      @command_ids = {}
    end

    def start!
      start_fcsh_process!
    end

    def compile! command, frontend
      @command, @frontend = command, frontend

      if have_command_id?
        recompile!
      else
        compile_new!
      end
    end

  private

    def start_fcsh_process!
      stop_fcsh_process!
      @logger.log "starting #{FlexHome.fcsh}"
      @fcsh_process = IO.popen("#{FlexHome.fcsh} 2>&1", "r+")
      read_until_prompt!
    end

    def stop_fcsh_process!
      if @fcsh_process
        @logger.log "killing fcsh process"
        @fcsh_process.close
        @fcsh_process = nil
        @command_ids = {}
      end
    end

    def compile_new!
      @frontend.flush
      send_fcsh_command! @command
      forward_compilation_output!
    ensure
      if not have_command_id?
        @logger.error "could not determine compilation ID"
        @frontend.puts "fcshd: internal error; see fcshd log"
        @frontend.flush
      end
    end

    def recompile!
      send_fcsh_command! "compile #{command_id}"
      forward_compilation_output!
    end

    def command_id
      @command_ids[@command]
    end

    def command_id= id
      @command_ids[@command] = id
    end

    def have_command_id?
      @command_ids.include? @command
    end

    def forward_compilation_output!
      for line in @output.lines
        case line
        when /^fcsh: Assigned (\d+) as the compile target id$/
          self.command_id = $1
        else
          @frontend.puts(line)
        end
      end
    end

    def send_fcsh_command! command
      @logger.log(command)
      @fcsh_process.puts(command)
      read_until_prompt!
    end

    FCSH_PROMPT = "\n(fcsh) "

    def read_until_prompt!
      @output_buffer << @fcsh_process.readpartial(256) until
        @output_buffer.include? FCSH_PROMPT
      @output, @output_buffer =
        @output_buffer.split(FCSH_PROMPT, 2)
      @logger.dump @output
    rescue EOFError
      @logger.dump @output_buffer
      @logger.die "could not find fcsh prompt"
    end
  end
end
