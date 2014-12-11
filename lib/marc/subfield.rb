module MARC

  # A class that represents an individual  subfield within a DataField.
  # Accessor attributes include: code (letter subfield code) and value
  # (the content of the subfield). Both can be empty string, but should
  # not be set to nil.

  class Subfield
    attr_accessor :code, :value

    def initialize(code='' ,value='')
      # can't allow code or value to be nil
      # or else it'll screw us up later on
      # nil.to_s == ''
      @code = code.to_s
      @value = value.to_s
    end

    def ==(other)
      @core == other.code and
        @value == other.value
    end

    def to_s
      return "$#{code} #{value} "
    end
  end
end
