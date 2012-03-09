# -*- coding: utf-8 -*-
module FCSHD
  class Compiler
    def initialize(logger)
      @logger = logger
      @output_buffer = ""
      @command_ids = {}
    end

    def start!; restart_fcsh_process! end
    def restart!; restart_fcsh_process! end

    def compile! command, frontend
      @command, @frontend = command, frontend

      log_horizontal_line

      if have_command_id?
        recompile!
      else
        compile_new!
      end
    end

  private

    def log_horizontal_line
      @logger.log("—" * 60)
    end

    def have_command_id?
      @command_ids.include? @command
    end

    def restart_fcsh_process!
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
      process_compilation_output!
    ensure
      if not have_command_id?
        report_internal_error "could not determine compilation ID"
      end
    end

    def recompile!
      send_fcsh_command! "compile #{command_id}"
      process_compilation_output!
    rescue FCSHError => error
      case error.message
      when "Error: null"
        @frontend.puts "fcshd: got mysterious error; restarting fcsh..."
        restart_fcsh_process!
        @frontend.puts "fcshd: retrying your compilation"
        compile_new!
      else
        report_internal_error "unknown fcsh error: #{error.message}"
      end
    end

    def command_id
      @command_ids[@command]
    end

    class FCSHError < StandardError; end

    def report_internal_error(message)
      @logger.error(message)
      @frontend.puts "fcshd: internal error; see fcshd log"
      @frontend.flush
    end

    def process_compilation_output!
      for line in @output.lines.map(&:chomp)
        case line
        when /^fcsh: Assigned (\d+) as the compile target id$/
          self.command_id = $1
        when "Error: null"
          raise FCSHError, line
        else
          @frontend.puts(line)
        end
      end
    end

    def command_id= id
      @command_ids[@command] = id
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
