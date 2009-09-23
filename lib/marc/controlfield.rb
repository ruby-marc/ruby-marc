require 'set'

module MARC

  # MARC records contain control fields, each of which has a 
  # tag and value. Tags for control fields must be in the
  # 001-009 range or be specially added to the @@control_tags Set

  class ControlField
    
    # Initially, control tags are the numbers 1 through 9 or the string '000'
    @@control_tags = Set.new( (1..9).to_a)
    @@control_tags << '000'
 
    def self.control_tags
      return @@control_tags
    end
 
    # A tag is a control tag if it is a member of the @@control_tags set
    # as either a string (e.g., 'FMT') or in its .to_i representation
    # (e.g., '008'.to_i == 3 is in @@control_tags by default)
  
    def self.control_tag?(tag)
      return (@@control_tags.include?(tag.to_i) or @@control_tags.include?(tag))
    end
    

    # the tag value (007, 008, etc)
    attr_accessor :tag

    # the value of the control field
    attr_accessor :value

    # The constructor which must be passed a tag value and 
    # an optional value for the field.

    def initialize(tag,value='')
      @tag = tag
      @value = value
      if not MARC::ControlField.control_tag?(@tag)
        raise MARC::Exception.new(), "tag must be in 001-009 or in the MARC::ControlField.control_tags set"
      end
    end

    # Two control fields are equal if their tags and values are equal.

    def ==(other)
      if @tag != other.tag
        return false 
      elsif @value != other.value
        return false
      end
      return true
    end

    # turning it into a marc-hash element
    def to_marchash
      return [@tag, @value]
    end
    

    def to_s
      return "#{tag} #{value}" 
    end

    def =~(regex)
      return self.to_s =~ regex
    end      

  end

end
