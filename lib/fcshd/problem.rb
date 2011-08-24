# -*- coding: utf-8 -*-
module FCSHD
  class Problem < Struct.new(:source_location, :raw_mxmlc_message)
    ERROR_PREFIX = /^Error: /

    def mxmlc_message
      raw_mxmlc_message.sub(ERROR_PREFIX, "")
    end

    def error?
      raw_mxmlc_message =~ ERROR_PREFIX
    end

    def quote(string)
      "‘#{string}’"
    end

    def message
      case mxmlc_message
      when /^Unable to resolve MXML language version/
        <<"^D"
Missing MXML version.
  Try  xmlns="http://www.adobe.com/2006/mxml       (for Flex 3)
   or  xmlns:fx="library://ns.adobe.com/mxml/2009  (for Flex 4)

Other useful namespaces for use in Flex 4 components:
  xmlns:s="library://ns.adobe.com/flex/spark"
  xmlns:mx="library://ns.adobe.com/flex/mx"
^D
      when
        /^Could not resolve <(.+)> to a component implementation.$/,
        /^Call to a possibly undefined method (.+).$/
      then
        <<"^D".tap do |result|
#{quote $1} undeclared
^D
          Compiler.find_standard_component($1).tap do |package|
            result << <<"^D" if package
maybe #{quote "import #{package}.*"}?
^D
          end
        end
      else
        mxmlc_message
      end
    end

    def formatted_message_lines
      message.lines.map do |line|
        if error?
          "error: #{line.chomp}"
        else
          line.chomp
        end
      end
    end
  end
end
