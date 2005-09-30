module MARC

    # A class that represents an individual MARC record. Every record
    # is made up of a collection of MARC::Field objects. 

    class Record
        include Enumerable

        LEADER_LENGTH = 24
        DIRECTORY_ENTRY_LENGTH = 12
        SUBFIELD_INDICATOR = 0x1F.chr
        END_OF_FIELD = 0x1E.chr
        END_OF_RECORD = 0x1D.chr

        # the record fields
        attr_accessor :fields,

        # the record leader
        :leader

        def initialize
            @fields = []
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

        # Pass in raw MARC21 in transmission format and get back a 
        # MARC::Record  object. Used by MARC::Reader to read records 
        # off of disk.

        def Record::decode(raw)
            record = Record.new()
            record.leader = raw[0..LEADER_LENGTH]

            # where the field data starts
            base_address = record.leader[12..16].to_i

            # get the byte offsets from the record directory
            directory = raw[LEADER_LENGTH..base_address-1]

            # the number of fields in the record corresponds to 
            # how many directory entries there are
            num_fields = directory.length / DIRECTORY_ENTRY_LENGTH

            0.upto(num_fields-1) do |field_num|

                # pull the directory entry for a field out
                entry_start = field_num * DIRECTORY_ENTRY_LENGTH
                entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
                entry = directory[entry_start..entry_end]
                
                # extract the tag, length and offset for pulling the
                # field out of the field portion
                tag = entry[0..2]
                length = entry[3..6].to_i
                offset = entry[7..11].to_i
                field_start = base_address + offset
                field_end = field_start + length - 1
                field_data = raw[field_start..field_end]

                # remove end of field
                field_data.delete!(END_OF_FIELD)
                
                # create a MARC::Field and add it to the record
                field = MARC::Field.decode(tag,field_data)
                record.append(field)
            end

            return record
        end

        # Returns the record serialized as MARC21

        def encode
            directory = ''
            fields = ''
            offset = 0
            for field in @fields:
                field_data = field.encode()
                field_length = field_data.length()
                directory += field.tag + sprintf('%04i',field_length) +
                    sprintf("05i",offset)
                fields += field_data
                offset += field_length

        end

        # Returns a string version of the record, suitable for printing

        def to_s
            str = "LEADER #{leader}\n"
            for field in fields:
                str += field.to_s() + "\n"
            end
            return str
        end

        # Handy for using a record in a regex:
        #     if record =~ /Gravity's Rainbow/ then print "Slothrop" end

        def =~(regex)
            return self.to_s =~ regex 
        end

    end

end
