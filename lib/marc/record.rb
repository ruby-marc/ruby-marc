module MARC

    # A class that represents an individual MARC record. Every record
    # is made up of a collection of MARC::Field objects. 

    class Record
        include Enumerable

        # the record fields
        attr_accessor :fields,

        # the record leader
        :leader

        def initialize
            @fields = []
            # leader is 24 bytes
            @leader = ' ' * 24
            # leader defaults:
            # http://www.loc.gov/marc/bibliographic/ecbdldrd.html
            @leader[10..11] = '22'
            @leader[20..23] = '4500';        
        end

        # add a field to the record
        #     record.append(MARC::Field.new( '100', '2', '0', ['a', 'Fred']))

        def append(field)
            @fields.push(field)
        end

        # each() is here to support iterating and searching since MARC::Record
        # mixes in Enumberable
        #
        # iterating through the fields in a record:
        #     record.each { |f| print f }
        #
        # getting the 245
        #     title = record.find {|f| f.tag == '245'}
        #
        # getting all subjects
        #     subjects = record.find_all {|f| ('600'..'699' === f.tag)}

        def each
            for field in @fields
                yield field
            end
        end

        # You can lookup fields using this shorthand:
        #     title = record['245']

        def [](tag)
            return self.find {|f| f.tag == tag}
        end

        # Factory method for creating a MARC::Record from MARC21 in 
        # transmission format. Really this is just a wrapper around
        # MARC::MARC21::decode
        #
        #     record = MARC::Record.new_from_marc(marc21)


        def Record::new_from_marc(raw)
            return MARC::MARC21.new().decode(raw)
        end


        # Handy method for returning a the MARC21 serialization for a 
        # MARC::Record object. Really this is just a wrapper around
        # MARC::MARC21::encode
        # 
        #     marc = record.to_marc()

        def to_marc 
            return MARC::MARC21.new().encode(self)
        end


        # Returns a string version of the record, suitable for printing

        def to_s
            str = "LEADER #{leader}\n"
            for field in fields:
                str += field.to_s() + "\n"
            end
            return str
        end


        # For testing if two records can be considered equal.

        def ==(other)
            if @leader != other.leader:
                return false
            elsif @fields.length != other.fields.length()
                return false
            else 
                for i in [0..@fields.length()]:
                    return false if @fields[i] != other.fields[i]
                end
            end
            return true
        end


        # Handy for using a record in a regex:
        #     if record =~ /Gravity's Rainbow/ then print "Slothrop" end

        def =~(regex)
            return self.to_s =~ regex 
        end

    end

end

