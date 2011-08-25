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
missing MXML version
→ xmlns="http://www.adobe.com/2006/mxml
→ xmlns:fx="library://ns.adobe.com/mxml/2009
  xmlns="library://ns.adobe.com/flex/spark"
  xmlns:mx="library://ns.adobe.com/flex/mx"
^D
      when /^Incorrect number of arguments.  Expected (\d+)\.$/
        "expected #$1 arguments"
      when /^(?:Access of possibly undefined property|Call to a possibly undefined method) (.+) through a reference with static type (.+)\.$/
      then
        <<"^D"
#{quote $1} undeclared in #$2
^D
      when
        /^Could not resolve <(.+)> to a component implementation.$/,
        /^Call to a possibly undefined method (.+).$/,
        /^Access of undefined property (.+).$/,
        /^The definition of base class (.+) was not found.$/,
        /^Type was not found or was not a compile-time constant: (.+)\.$/
      then
        <<"^D".tap do |result|
#{quote $1} undeclared
^D
          Compiler.find_standard_component($1).tap do |package|
            result << <<"^D" if package
→ import #{package}.*
^D
          end
        end
      when /^Implicit coercion of a value of type (.+) to an unrelated type (.+)\.$/
        "expected #$2 (got #$1)"
      when "Method marked override must override another method."
        "overriding nonexistent method"
      when "Overriding a function that is not marked for override."
        <<"^D"
unmarked override
→ add override keyword
^D
      when "Incompatible override."
        "incompatible override"
      when /^Ambiguous reference to (.+)\.$/
        "#{quote $1} is ambiguous"
      when /^Warning: return value for function '(.+)' has no type declaration\.$/
        "missing return type for #{quote $1}"
      else
        mxmlc_message
      end
    end

    def formatted_message_lines
      lines = message.lines.entries
      if error?
        first = <<"^D"
error: #{lines[0].chomp}
^D
        rest = lines[1..-1].map do |line|
          <<"^D"
       #{line.chomp}
^D
        end
        [first] + rest
      else
        lines
      end
    end
  end
end
