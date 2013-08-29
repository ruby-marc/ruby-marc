module MARC

  # A class for writing MARC records as MARC21.

  class Writer

    # the constructor which you must pass a file path
    # or an object that responds to a write message

    def initialize(file)
      if file.class == String
        @fh = File.new(file,"w")
      elsif file.respond_to?('write')
        @fh = file
      else
        throw "must pass in file name or handle"
      end
    end


    # write a record to the file or handle

    def write(record)
      @fh.write(MARC::Writer.encode(record))
    end


    # close underlying filehandle

    def close
      @fh.close
    end


    # a static method that accepts a MARC::Record object
    # and returns the record encoded as MARC21 in transmission format

    def self.encode(record)
      directory = ''
      fields = ''
      offset = 0
      for field in record.fields

        # encode the field
        field_data = ''
        if field.class == MARC::DataField 
          warn("Warn:  Missing indicator") unless field.indicator1 && field.indicator2
          field_data = (field.indicator1 || " ") + (field.indicator2 || " ")
          for s in field.subfields
            field_data += SUBFIELD_INDICATOR + s.code + s.value
          end
        elsif field.class == MARC::ControlField
          field_data = field.value
        end
        field_data += END_OF_FIELD

        # calculate directory entry for the field
        field_length = (field_data.respond_to?(:bytesize) ?
          field_data.bytesize() :
          field_data.length())
        directory += sprintf("%03s", field.tag) + format_byte_count(field_length, 4) + format_byte_count(offset)


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
      marc[12..16] = format_byte_count(base.respond_to?(:bytesize) ?
        base.bytesize() :
        base.length()
      )

      # update the record length
      marc[0..4] = format_byte_count(marc.respond_to?(:bytesize) ?
        marc.bytesize() :
        marc.length()
      )
      
      # store updated leader in the record that was passed in
      record.leader = marc[0..LEADER_LENGTH-1]

      # return encoded marc
      return marc
    end

    def self.format_byte_count(number, num_digits=5)
      formatted = sprintf("%0#{num_digits}i", number)
      if formatted.length > num_digits
        # uh, oh, we've exceeded our max. Either zero out
        # or raise, depending on settings.
        formatted = sprintf("%0#{num_digits}i", 0)
        #formatted = "9" * num_digits
      end
      return formatted
    end

  end
end
