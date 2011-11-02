# -*- coding: utf-8 -*-

module FCSHD
  class Problem < Struct.new(:source_location, :raw_mxmlc_message)
    ERROR_PREFIX = /^\s*Error: /

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
      case raw = raw_message
      when String then raw
      when Array then raw * "\n"
      else fail
      end
    end

    def raw_message
      case mxmlc_message

      when "Unable to resolve MXML language version. Please specify the language namespace on the root document tag."
      then
        <<"^D"
missing MXML version
→ xmlns:fx="library://ns.adobe.com/mxml/2009"
→ xmlns="library://ns.adobe.com/flex/spark"
→ xmlns:mx="library://ns.adobe.com/flex/mx" (Flex 3 compatibility)
→ xmlns="http://www.adobe.com/2006/mxml" (Flex 3)
^D

      when /^Incorrect number of arguments.  Expected (\d+)\.$/
      then "expected #$1 arguments"

      when /^(?:Access of possibly undefined property|Call to a possibly undefined method) (.+) through a reference with static type (.+)\.$/
      then "#{quote $1} undeclared in #$2"

      when /^Attempted access of inaccessible property (.+) through a reference with static type (.+)\.$/
      then "#{quote $1} inaccessible in #$2"

      when
        /^Could not resolve <(.+)> to a component implementation.$/,
        /^Call to a possibly undefined method (.+).$/,
        /^Access of undefined property (.+).$/,
        /^The definition of base class (.+) was not found.$/,
        /^Type was not found or was not a compile-time constant: (.+)\.$/
      then
        ["#{quote $1} undeclared"].tap do |result|
          FlexHome.find_component($1).tap do |package|
            result << "→ import #{package}.*" if package
          end
        end

      when /^Definition (.+) could not be found\.$/
      then "#{quote $1} not found"

      when
        /^Implicit coercion of a value of type (.+) to an unrelated type (.+)\.$/,

        /^Implicit coercion of a value with static type (.+) to a possibly unrelated type (.+)\./

      then
        actual, expected = $1, $2
        expected_base = expected.sub(/.+:/, "")
        actual_base = actual.sub(/.+:/, "")
        if actual_base != expected_base
          "expected #{expected_base} (got #{actual_base})"
        else
          "expected #{expected} (got #{actual})"
        end

      when "Method marked override must override another method."
      then "overriding nonexistent method"

      when "Overriding a function that is not marked for override."
      then ["unmarked override", "→ add override keyword"]

      when "Incompatible override."
      then "incompatible override"

      when /^Ambiguous reference to (.+)\.$/
      then "#{quote $1} is ambiguous"

      when /^A conflict exists with definition (.+) in namespace internal\.$/
      then "#{quote $1} is conflicting"

      when
        /^Warning: parameter '(.+)' has no type declaration\.$/,
        /^Warning: return value for function '(.+)' has no type declaration\.$/
      then
        case $1
        when "anonymous" then "anonymous function"
        else quote $1
        end + " missing type declaration"

      when /^A file found in a source-path must have the same package structure '(.*)', as the definition's package, '(.*)'\.$/
      then "package should be #{quote $1}"

      when /^Comparison between a value with static type (.+) and a possibly unrelated type (.+)\.$/
      then "comparing #$1 to #$2"

      when "Illegal assignment to a variable specified as constant."
      then "modifying constant"

      when "Function does not have a body."
      then "missing function body"

      when "Return type of a setter definition must be unspecified or void."
      then "setter must return void"

      when "Function does not return a value."
      then "missing return statement"

      when "Syntax error: expecting identifier before rightparen."
      then "#{quote ")"} unexpected"

      when
        /^The (.+) attribute can only be used inside a package\./,
        /^The (.+) attribute may be used only on class property definitions\./
      then
        "#{quote $1} unexpected"

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
