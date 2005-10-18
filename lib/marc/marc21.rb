module MARC

    # Provides methods for serializing and deserializing MARC::Record
    # objects as MARC21 in transmission format.

    class MARC21

        LEADER_LENGTH = 24
        DIRECTORY_ENTRY_LENGTH = 12
        SUBFIELD_INDICATOR = 0x1F.chr
        END_OF_FIELD = 0x1E.chr
        END_OF_RECORD = 0x1D.chr


        # Returns the MARC21 serialization for a MARC::Record 

        def encode(record)
            directory = ''
            fields = ''
            offset = 0
            for field in record.fields

                # encode the field
                field_data = ''
                if field.class == MARC::Field
                    field_data = field.indicator1 + field.indicator2 
                    for s in field.subfields
                        field_data += SUBFIELD_INDICATOR + s.code + s.value
                    end
                elsif field.class == MARC::Control
                    field_data = field.value
                end
                field_data += END_OF_FIELD

                # calculate directory entry for the field
                field_length = field_data.length()
                directory += sprintf("%03s%04i%05i", field.tag, field_length, 
                    offset)

                # add field to data for other fields
                fields += field_data 

                # update offset for next field
                offset += field_length
            end

            # determine the base (leader + directory)
            base = record.leader + directory + END_OF_FIELD

            # determine complete record
            marc = base + fields + END_OF_RECORD

            # update leader with the byte offest to the end of the directory
            marc[12..16] = sprintf("%05i", base.length())

            # update the record length
            marc[0..4] = sprintf("%05i", marc.length())
            
            # store updated leader in the record that was passed in
            record.leader = marc[0..LEADER_LENGTH]

            # return encoded marc
            return marc 
        end


        # Deserializes MARC21 as a MARC::Record object

        def decode(marc, params={})
            record = Record.new()
            record.leader = marc[0..LEADER_LENGTH]

            # where the field data starts
            base_address = record.leader[12..16].to_i

            # get the byte offsets from the record directory
            directory = marc[LEADER_LENGTH..base_address-1]

            # the number of fields in the record corresponds to 
            # how many directory entries there are
            num_fields = directory.length / DIRECTORY_ENTRY_LENGTH

            # when operating in forgiving mode we just split on end of
            # field instead of using calculated byte offsets from the 
            # directory
            all_fields = marc[base_address..-1].split(END_OF_FIELD)

            0.upto(num_fields-1) do |field_num|

                # pull the directory entry for a field out
                entry_start = field_num * DIRECTORY_ENTRY_LENGTH
                entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
                entry = directory[entry_start..entry_end]
                
                # extract the tag
                tag = entry[0..2]

                # get the actual field data
                # if we were told to be forgiving we just use the
                # next available chuck of field data that we 
                # split apart based on the END_OF_FIELD
                field_data = ''
                if params[:forgiving]
                    field_data = all_fields.shift()

                # otherwise we actually use the byte offsets in 
                # directory to figure out what field data to extract
                else
                    length = entry[3..6].to_i
                    offset = entry[7..11].to_i
                    field_start = base_address + offset
                    field_end = field_start + length - 1
                    field_data = marc[field_start..field_end]
                end

                # remove end of field
                field_data.delete!(END_OF_FIELD)
               
                # add a control field or variable field
                if tag < '010'
                    record.append(MARC::Control.new(tag,field_data))
                else
                    field = MARC::Field.new(tag)

                    # get all subfields
                    subfields = field_data.split(SUBFIELD_INDICATOR)

                    # get indicators
                    indicators = subfields.shift()
                    field.indicator1 = indicators[0,1]
                    field.indicator2 = indicators[1,1]

                    # add each subfield to the field
                    subfields.each() do |data|
                        subfield = MARC::Subfield.new(data[0,1],data[1..-1])
                        field.append(subfield)
                    end

                    # add the field to the record
                    record.append(field)
                end
            end

            return record
        end

    end

end
