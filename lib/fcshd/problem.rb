module FCSHD
  class Problem < Struct.new(:source_location, :message_lines)
    def self.[] source_location, mxmlc_message
      new(source_location, parse_message(mxmlc_message))
    end

    def self.parse_message(mxmlc_message)
      case mxmlc_message
      when /^Unable to resolve MXML language version/
        <<"^D"
Missing MXML version.
  Try xmlns="http://www.adobe.com/2006/mxml
   or xmlns:fx="library://ns.adobe.com/mxml/2009
^D
      when /^Could not resolve <(.+)> to a component implementation.$/
        <<"^D"
`#$1' is undefined.
^D
      end.lines.map(&:chomp)
    end
  end
end
