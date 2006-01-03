module MARC

  # A class for representing fields with a tag less than 010.
  # Ordinary MARC::Field objects are for fields with tags >= 010
  # which have indicators and subfields.

  class Control

    # the tag value (007, 008, etc)
    attr_accessor :tag

    # the value of the control field
    attr_accessor :value

    # The constructor which must be passed a tag value and 
    # an optional value for the field.

    def initialize(tag,value='')
      @tag = tag
      @value = value
      if tag.to_i > 9 
        raise MARC::Exception.new(), "tag must be greater than 009"
      end
    end

    def to_s
      return "#{tag} #{value}" 
    end

    def =~(regex)
      return self.to_s =~ regex
    end

  end

end
