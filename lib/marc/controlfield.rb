require 'set'

module MARC

  # MARC records contain control fields, each of which has a
  # tag and value. Tags for control fields must be in the
  # 001-009 range or be specially added to the @@control_tags Set

  class ControlField

    # Initially, control tags are the numbers 1 through 9 or the string '000'
    @@control_tags = Set.new(%w{000 001 002 003 004 005 006 007 008 009})

    def self.control_tags
      return @@control_tags
    end

    # A tag is a control tag if tag.to_s is a member of the @@control_tags set.
    def self.control_tag?(tag)
      return @@control_tags.include? tag.to_s
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
      tag == other.tag && value == other.value
    end

    # turning it into a marc-hash element
    def to_marchash
      return [@tag, @value]
    end

    # Turn the control field into a hash for MARC-in-JSON
    def to_hash
      return {@tag=>@value}
    end

    def to_s
      return "#{tag} #{value}"
    end

    def =~(regex)
      return self.to_s =~ regex
    end

  end

end
