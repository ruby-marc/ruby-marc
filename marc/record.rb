module MARC

    # A class that represents an individual MARC record. Every record
    # is made up of a collection of MARC::Field objects. 

    class Record
        include Enumerable

        # the record fields
        attr_accessor :fields

        def initialize
            @fields = []
        end

        # add a field to the record
        #     record.append(MARC::Field.new( '100', '2', '0', ['a', 'Fred']))

        def append(field)
            @fields.push(field)
        end

        # to support iterating on the fields in a record
        #     record.each { |f| print f }

        def each
            for field in @fields
                yield field
            end
        end

    end

end
