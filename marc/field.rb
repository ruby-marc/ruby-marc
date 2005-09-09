require 'marc/subfield'

class Field
    include Enumerable
    attr_accessor :tag, :indicator1, :indicator2, :subfields

    def initialize(tag,i1=nil,i2=nil,*subfields)
        @tag = tag 
        @indicator1 = i1
        @indicator2 = i2
        @subfields = unpack(subfields) 
    end

    def to_a
        str = "#{tag} #{indicator1}#{indicator2} "
        subfields.each { |subfield| str += subfield.to_a }
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
        for subfield in @subfields:
            yield subfield
        end
    end

end
