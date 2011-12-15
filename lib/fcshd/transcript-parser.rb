module FCSHD
  class Transcript; end
  class Transcript::Parser < Struct.new(:lines)
    def parse!
      Transcript.new.tap do |result|
        @result = result
        parse_line! until lines.empty?
      end
    end

    attr_reader :result

    def parse_line!
      take_line! do |line|
        case FCSHD.trim(line)
        when / \((\d+) bytes\)$/
          result.succeeded = true

        when "Nothing has changed since the last compile. Skip..."
          result.n_compiled_files = 0

        when /^Files changed: (\d+) Files affected: (\d+)$/
          result.n_compiled_files = $1.to_i + $2.to_i

        when /^(\/.+?)(?:\((\d+)\))?: (?:col: \d+ )?(.+)$/
          result << Transcript::Item[SourceLocation[$1, $2.to_i], $3]
          skip_indented_lines! # Ignore the "diagram" of the problem.

        when /^Required RSLs:$/
          skip_indented_lines! # Does anybody care about this?

        when /^(Recompile|Reason|Updated): /
        when /^Loading configuration file /
        when "Detected configuration changes. Recompile..."

        else
          # Let unrecognized lines pass through verbatim.
          if line.start_with? "fcshd: "
            result << line
          else
            # XXX: What about when we support compc?
            result << "mxmlc: #{line}"
          end
        end
      end
    end

    def take_line!
      yield skip_line!
    end

    def skip_line!
      current_line
    ensure
      lines.shift
    end

    def current_line
      lines.first.chomp
    end

    def skip_indented_lines!
      skip_line! until lines.empty? or current_line =~ /^\S/
    end
  end
end
