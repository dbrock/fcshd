module FCSHD
  class Problem < Struct.new(:location, :message)
    def to_s(basedir)
      "#{location.to_s(basedir)}: #{message}"
    end
  end
end
