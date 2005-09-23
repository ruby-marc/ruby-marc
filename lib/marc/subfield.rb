module MARC

    class Subfield
        attr_accessor :code, :value

        def initialize(code,value)
            @code = code
            @value = value
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
            return "$#{code}#{value}"
        end
    end

end
