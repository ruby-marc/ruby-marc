module MARC

  class Subfield
    attr_accessor :code, :value

    def initialize(code='' ,value='')
      # can't allow code of value to be nil
      # or else it'll screw us up later on
      @code = code == nil ? '' : code
      @value = value == nil ? '' : value
    end

    def ==(other)
      if @code != other.code
        return false
      elsif @value != other.value
        return false
      end
      return true
    end

    def to_s
      return "$#{code} #{value} "
    end
  end
end
