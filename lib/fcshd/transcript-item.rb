# -*- coding: utf-8 -*-

module FCSHD
  class Transcript; end
  class Transcript::Item < Struct.new(:location, :mxmlc_message)
    def to_s(basedir)
      problems.map { |problem| problem.to_s(basedir) + "\n" }
    end

    def problems
      get_problems(parsed_message)
    end

  private

    def get_problems(item)
      case item
      when String
        get_problems_at(location, item)
      when Array
        if item.first.is_a? SourceLocation
          get_problems_at(item[0], item[1])
        else
          item.map { |item| get_problems(item) }.flatten(1)
        end
      else fail
      end
    end

    def get_problems_at(location, message)
      message.split("\n").map do |message|
        Problem[location, message]
      end
    end

    def format_type(type)
      case type
      when /^__AS3__\.vec:Vector\.<(.*)>$/
        "Vector.<#{$1.sub(/.+:/, "")}>"
      else
        type.sub(/.+:/, "")
      end
    end

    def parsed_message
      case FCSHD.trim(mxmlc_message).sub(/^Error: /, "")
      when "Unable to resolve MXML language version. Please specify the language namespace on the root document tag." then <<EOF
error: missing MXML version
error: hint: xmlns:fx="library://ns.adobe.com/mxml/2009"
error: hint: xmlns="library://ns.adobe.com/flex/spark"
error: hint: xmlns:mx="library://ns.adobe.com/flex/mx" (Flex 4)
error: hint: xmlns="http://www.adobe.com/2006/mxml" (Flex 3)
EOF
      when /^Incorrect number of arguments. Expected (\d+)\.$/ then <<EOF
error: expected #$1 arguments
EOF
      when /^Incorrect number of arguments. Expected no more than (\d+)\.$/ then <<EOF
error: expected at most #$1 arguments
EOF
      when
        /^Access of possibly undefined property (.+) through a reference with static type (.+)\.$/,
        /^Call to a possibly undefined method (.+) through a reference with static type (.+)\.$/,
        /^Cannot resolve attribute '(.+)' for component type (.+)\.$/
      then <<EOF
error: #{quote $1} undeclared in #{name $2}
EOF
      when /^Attempted access of inaccessible property (.+) through a reference with static type (.+)\.$/ then <<EOF
error: #{quote $1} inaccessible in #{name $2}
EOF
      when
        /^Could not resolve <(.+)> to a component implementation\.$/,
        /^Call to a possibly undefined method (.+)\.$/,
        /^Access of undefined property (.+)\.$/,
        /^The definition of base class (.+) was not found\.$/,
        /^Unable to locate specified base class '(.+)' for component class '.*'\.$/,
        /^Interface (.+) was not found\.$/,
        /^Type was not found or was not a compile-time constant: (.+)\.$/
      then
         [<<EOF].tap do |result|
error: #{quote $1} undefined
EOF
          FlexHome.find_component($1).tap do |package|
            result << <<EOF if package
error: hint: import #{package}.#$1
EOF
          end
        end
      when /^Definition (.+) could not be found\.$/ then <<EOF
error: #{quote $1} not found
EOF
      when /^Implicit coercion of a value of type (.+) to an unrelated type (.+)\.$/, /^Implicit coercion of a value with static type (.+) to a possibly unrelated type (.+)\./
        actual, expected = $1, $2
        if format_type(actual) != format_type(expected)
        then <<EOF else <<EOF end
error: expected #{format_type(expected)} (got #{format_type(actual)})
EOF
error: expected #{expected} (got #{actual})
EOF
      when "Method marked override must override another method." then <<EOF
error: overriding nonexistent method
EOF
      when "Overriding a function that is not marked for override." then <<EOF
error: unmarked override
EOF
      when "Incompatible override." then <<EOF
error: incompatible override
EOF
      when /^Ambiguous reference to (.+)\.$/ then <<EOF
error: #{quote $1} is ambiguous
EOF
      when /^Can not resolve a multiname reference unambiguously. (\S+) \(from ([^)]+)\) and (\S+) \(from ([^)]+)\) are available\.$/
      then
        [<<EOF, [SourceLocation[$2], <<EOF], [SourceLocation[$4], <<EOF]]
error: #{quote name $1} conflicts with #{quote name $3}
EOF
error: conflicting definition
EOF
error: conflicting definition
EOF
      when /^A conflict exists with definition (.+) in namespace internal\.$/ then <<EOF
error: #{quote $1} conflicts with an internal name
EOF
      when /^Warning: return value for function '(.+)' has no type declaration\.$/ then
        <<EOF
error: #{quote($1) + " " unless $1 == "anonymous"}missing return type
EOF
      when /^Warning: parameter '(.+)' has no type declaration\.$/ then <<EOF
error: #{quote($1)} missing type
EOF

       when "Warning: This compilation unit did not have a factoryClass specified in Frame metadata to load the configured runtime shared libraries. To compile without runtime shared libraries either set the -static-link-runtime-shared-libraries option to true or remove the -runtime-shared-libraries option."
       then []

      when /^A file found in a source-path must have the same package structure '(.*)', as the definition's package, '(.*)'\.$/ then <<EOF
error: package should be #{quote $1}
EOF
      when /^A file found in a source-path '(.*)' must have the same name as the class definition inside the file '(.*)'\.$/ then <<EOF
error: name should be #{quote $1}
EOF
      when /^Comparison between a value with static type (.+) and a possibly unrelated type (.+)\.$/ then <<EOF
error: comparing #$1 to #$2
EOF
      when "Illegal assignment to a variable specified as constant." then <<EOF
error: modifying constant
EOF
      when "Function does not have a body." then <<EOF
error: missing function body"
EOF
      when "Return type of a setter definition must be unspecified or void." then <<EOF
error: setter must return void"
EOF
      when "Function does not return a value." then <<EOF
error: missing return statement"
EOF
      when
        /^The (.+) attribute can only be used inside a package\./,
        /^The (.+) attribute may be used only on class property definitions\./
      then
        <<EOF
error: #{quote $1} unexpected
EOF
      when /^Syntax error: expecting (.+?) before (.+?)\.$/
        <<EOF
error: missing #{lexeme($1)} (found #{lexeme($2)} instead)
EOF

      when "Syntax error: XML does not have matching begin and end tags."
        <<EOF
error: XML tag mismatch
EOF
      else
        mxmlc_message
      end
    end

    def name(string) string.sub!(":", ".") end
    def quote(string) "‘#{string}’" end

    def lexeme(name)
      parse_line = lambda { |line| line.chomp.split(/\s*\|\s*/, 2) }
      Hash[<<EOF.lines.map(&parse_line)][name] || quote(name)
colon          | ‘:’
semicolon      | ‘;’
leftparen      | ‘(’
rightparen     | ‘)’
leftbracket    | ‘[’
rightbracket   | ‘]’
leftbrace      | ‘{’
rightbrace     | ‘}’
xmltagstartend | ‘</>’
identifier     | expression
end of program | eof
EOF
    end
  end
end
