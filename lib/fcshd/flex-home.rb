require "find"

module FCSHD
  module FlexHome
    extend self

    def default
      "/usr/local/flex"
    end

    def known?
      !value.nil?
    end

    def value
      ENV["FLEX_HOME"] or
        if File.directory? default
          default
        else
          nil
        end
    end

    def to_s
      value
    end

    def [](*components)
      File.join(value, *components)
    end

    # ------------------------------------------------------

    def fcsh
      self["bin/fcsh"]
    end

    def framework_lib_dirs
      [].tap do |result|
        Find.find(self["frameworks/libs"]) do |file|
          result << file if File.directory? file
        end
      end
    end

    def halo_swc
      self["frameworks/themes/Halo/halo.swc"]
    end

    # ------------------------------------------------------

    def find_component(name)
      Find.find(self["frameworks/projects"]) do |filename|
        break File.dirname(filename).sub(%r{.+/src/}, "").gsub("/", ".") if
          File.basename(filename).sub(/\..*/, "") == name
      end
    end
  end
end
