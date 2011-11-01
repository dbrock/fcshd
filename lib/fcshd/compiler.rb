require "find"

module FCSHD
  module FlexHome
    extend self

    DEFAULT_FLEX_HOME = "/Library/Flex"

    def known?
      !!flex_home
    end

    def fcsh
      flex_path("bin", "fcsh")
    end

    def find_standard_component(name)
      Find.find(standard_source_directory_root) do |filename|
        if barename(filename) == name
          break File.dirname(filename).
            sub(%r{.+/src/}, "").gsub("/", ".")
        end
      end
    end

  private

    def flex_home
      ENV["FLEX_HOME"] or
        if File.directory? DEFAULT_FLEX_HOME
          DEFAULT_FLEX_HOME
        else
          nil
        end
    end

    def flex_path(*components)
      File.join(flex_home, *components)
    end

    def standard_source_directory_root
      flex_path("frameworks", "projects")
    end

    def barename(filename)
      File.basename(filename).sub(/\..*/, "")
    end
  end

  class Compiler
    def initialize(logger)
      @logger = logger
      @output_buffer = ""
    end

    def start!
      ensure_flex_home_known!
      start_fcsh_process!
      parse_fcsh_boilerplate!
      @logger.log "Started Flex #@flex_version compiler shell."
    rescue PromptNotFound => error
      @logger.error "Could not find fcsh prompt:"
      @logger.error @logger.format_command(FlexHome.fcsh, error.message)
      @logger.exit
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

    def ensure_flex_home_known!
      if not FlexHome.known?
        @logger.log <<"^D" 
Please put the Flex SDK in #{FlexHome::DEFAULT_FLEX_HOME} or set $FLEX_HOME.
^D
        @logger.exit
      end
    end

    def start_fcsh_process!
      stop_fcsh_process!
      @fcsh_process = IO.popen("#{FlexHome.fcsh} 2>&1", "r+")
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

    def compile_new!
      @frontend.puts "fcshd: Compiling from scratch..."
      @frontend.flush
      send_fcsh_command! @command
      parse_compilation_output!
    ensure
      if not have_command_id?
        @logger.error "Could not determine compilation ID:"
        @logger.error @logger.format_command("(fcsh) #@command", @output)
      end
    end

    def recompile!
      send_fcsh_command! "compile #{command_id}"
      parse_compilation_output!
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

    def parse_compilation_output!
      for line in @output.lines
        case line
        when /^fcsh: Assigned (\d+) as the compile target id$/
          self.command_id = $1
        else
          @frontend.puts(line)
          @logger.log_raw(line) if line =~ /^fcsh: /
        end
      end
    end

    def send_fcsh_command! command
      @logger.log_raw("> #{command}")
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
    rescue EOFError
      raise PromptNotFound, @output_buffer
    end
  end
end
