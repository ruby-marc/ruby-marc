require 'marc/subfield'
require 'marc/record'

module MARC

    # MARC records are made up of fields, each of which has a tag, 
    # indicators and subfields. If the tag is between 000-009 it is 
    # known as a control field, and actually does not have any 
    # indicators.

    class Field
        include Enumerable

        # The tag for the field
        attr_accessor :tag

        # The first indicator
        attr_accessor :indicator1

        # The second indicator
        attr_accessor :indicator2

        # A list of MARC::Subfield objects
        attr_accessor :subfields

        # Create a new field with tag, indicators and subfields.
        # Subfields are passed in as comma separated list of 
        # MARC::Subfield objects, 
        # 
        #     field = MARC::Field.new('245','0','0',
        #         MARC::Subfield.new('a', 'Consilience :'),
        #         MARC::Subfield.new('b', 'the unity of knowledge ',
        #         MARC::Subfield.new('c', 'by Edward O. Wilson.'))
        # 
        # or using a shorthand:
        # 
        #     field = MARC::Field.new('245','0','0',
        #         ['a', 'Consilience :'],['b','the unity of knowledge ',
        #         ['c', 'by Edward O. Wilson.'] )

        def initialize(tag, i1=nil, i2=nil, *subfields)
            @tag = tag 
            @indicator1 = i1
            @indicator2 = i2
            @subfields = []

            # allows MARC::Subfield objects to be passed directly
            # or a shorthand of ['a','Foo'], ['b','Bar']
            subfields.each do |subfield| 
                case subfield
                when MARC::Subfield
                    @subfields.push(subfield)
                when Array
                    if subfield.length > 2
                        raise "arrays must only have 2 elements" 
                    end
                    @subfields.push(
                        MARC::Subfield.new(subfield[0],subfield[1]))
                else 
                    raise "invalid subfield type #{subfield.class}"
                end
            end
        end

        # returns true if the field is between 000 and 009 and lacks indicators

        def is_control
            return ('000'..'009') === @tag
        end

        # Returns a string representation of the field such as:
        #  245 00 $aConsilience :$bthe unity of knowledge $cby Edward O. Wilson.

        def to_s
            str = "#{tag} "
            str += "#{indicator1}#{indicator2} " unless is_control()
            @subfields.each { |subfield| str += subfield.to_s }
            return str
        end

        # add a subfield (MARC::Subfield) to the field
        #      field.append(MARC::Subfield('a','Dave Thomas'))

        def append(subfield)
            @subfields.push(subfield)
        end

        # You can iterate through the subfields in a Field:
        #     field.each {|s| print s}

        def each
            for subfield in subfields
                yield subfield
            end
        end

        # Two fields are equal if their tag, indicators and 
        # subfields are all equal.

        def ==(other)
            if @tag != other.tag
                return false 
            elsif @indicator1 != other.indicator1
                return false 
            elsif @indicator2 != other.indicator2
                return false 
            elsif @subfields != other.subfields
                return false
            end
            return true
        end

        # To build a field from a MARC21 field definition
        # Used by MARC::Record::decode

        def Field.decode(tag, raw)
            field = Field.new(tag)
            subfields = raw.split(MARC::Record::SUBFIELD_INDICATOR)

            # if it's not a control field pull off the indicators
            if not field.is_control()
                indicators = subfields.shift()
                field.indicator1 = indicators[0,1]
                field.indicator2 = indicators[1,1]
            end

            # add each subfield to the field
            subfields.each() do |data|
                subfield = MARC::Subfield.new(data[0,1],data[1..-1])
                field.append(subfield)
            end

            # return the field
            return field
        end

    end
end
