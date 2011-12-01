module FCSHD
  module FlexHome
    extend self

    def default
      "/Library/Flex"
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

    def libs
      self["frameworks/libs"]
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
