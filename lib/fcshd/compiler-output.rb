module FCSHD
  class CompilerOutput
    def self.[] text, basedir
      new.tap do |result|
        Parser.new(text.lines.entries, basedir, result).parse!
      end
    end

    attr_accessor :n_compiled_files

    def initialize
      @events = []
    end

    def << event
      @events << event
    end

    def write! writer
      writer.write! self do
        for event in @events
          case event
          when String
            writer.write_uninterpreted_line! event
          when Problem
            writer.write_problem! event
          end
        end
      end
    end

    def nothing_to_do?
      n_compiled_files == 0
    end

    def succeeded!
      @succeeded = true
    end

    def succeeded?
      @succeeded
    end

    class Parser < Struct.new(:lines, :basedir, :result)
      def parse!
        parse_line! until lines.empty?
      end

      def parse_line!
        take_line! do |line|
          case line
          when /^(Recompile|Reason): /
          when /^Loading configuration file /
          when /^(.+\.swf) \((\d+) bytes\)$/
            result.succeeded!
          when "Nothing has changed since the last compile. Skip..."
            result.n_compiled_files = 0
          when /^Files changed: (\d+) Files affected: (\d+)$/
            result.n_compiled_files = $1.to_i + $2.to_i
          when /^(\/.+?)(?:\((\d+)\))?:(?: Error:)? (.+)$/
            location = SourceLocation[$1, $2.to_i, nil, basedir]
            result << Problem[location, $3]
            skip_indented_lines!
          when /^Required RSLs:$/
            skip_indented_lines!
          else
            result << line
          end
        end
      end

      def take_line!
        yield skip_line!
      end

      def skip_line!
        lines.shift
      end

      def current_line
        lines[0].chomp
      end

      def skip_indented_lines!
        skip_line! until lines.empty? or current_line =~ /^\S/
      end
    end
  end
end
