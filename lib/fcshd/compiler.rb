require "find"

module FCSHD
  class Compiler
    FLEX_HOME = ENV["FLEX_HOME"]

    def self.flex_path(*components)
      File.join(FLEX_HOME, *components)
    end

    def self.standard_fcsh_executable
      FLEX_HOME ? flex_path("bin", "fcsh") : "fcsh"
    end

    def self.standard_source_directory_root
      flex_path("frameworks", "projects")
    end

    def self.barename(filename)
      File.basename(filename).sub(/\..*/, "")
    end

    def self.find_standard_component(name)
      if FLEX_HOME
        Find.find(standard_source_directory_root) do |filename|
          if barename(filename) == name
            break File.dirname(filename).
              sub(%r{.+/src/}, "").gsub("/", ".")
          end
        end
      end
    end

    FCSH_EXECUTABLE = ENV["FCSH"] ||

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
      @command = command

      if have_command_id?
        recompile!
      else
        compile_new!
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

    def compile_new!
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
        when /^fcsh: /
          @logger.log_raw(line)
          @output_lines << line
        else
          @output_lines << line
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
      @output_lines = []
    rescue EOFError
      raise PromptNotFound, @output_buffer
    end
  end
end
