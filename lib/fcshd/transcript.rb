module FCSHD
  class Transcript
    def self.[] text
      Parser.new(text.split("\n")).parse!
    end

    def initialize
      @items = []
    end

    def << item
      @items << item
    end

    attr_accessor :n_compiled_files

    def succeeded= value; @succeeded = value; end
    def succeeded?; @succeeded; end

    def to_s(basedir)
      @items.map do |item|
        case item
        when Item
          item.to_s(basedir)
        else
          item
        end
      end.join
    end

    def nothing_to_do?
      n_compiled_files == 0
    end
  end
end
