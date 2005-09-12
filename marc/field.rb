require 'marc/subfield'

module MARC

    class Field
        include Enumerable
        attr_accessor :tag, :indicator1, :indicator2, :subfields

        def initialize(tag,i1=nil,i2=nil,*subfields)
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

        def to_s
            str = "#{tag} #{indicator1}#{indicator2} "
            subfields.each { |subfield| str += subfield.to_s }
            return str
        end

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

        def each
            for subfield in subfields
                yield subfield
            end
        end

    end

end
