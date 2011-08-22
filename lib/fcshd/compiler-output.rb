module FCSHC
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
        for event in events
          case event
          when String
            writer.write_uninterpreted_line! event
          when Problem
            writer.write_problem! problem
          end
        end
      end
    end

    class Parser < Struct.new(:lines, :basedir, :result)
      def parse!
        parse_line! until lines.empty?
      end

      def parse_line!
        case line
        when /^(Recompile|Reason): /
        when /^Loading configuration file /
        when "Nothing has changed since the last compile. Skip..."
          result.n_compiled_files = 0
        when /^Files changed: (\d+) Files affected: (\d+)$/
          result.n_compiled_files = $1.to_i + $2.to_i
        when /^(\/.+?)(?:\((\d+)\))?:(?: Error:)? (.+)$/
          location = SourceLocation[$1, $2.to_i, nil, basedir]
          result.add_problem! Problem[location, $3]
          skip_following_indented_lines!
        when /^Required RSLs:$/
          skip_following_indented_lines!
        when /^(.+\.swf) \((\d+) bytes\)$/
        else
          result.add_uninterpreted_line! line
        end
        skip_line!
      end

      def skip_following_indented_lines!
        skip_next_line! while next_line =~ /^\s/
      end

      def skip_line!
        lines.unshift
      end

      def line
        lines[0].chomp
      end
    end
  end
end