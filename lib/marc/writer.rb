module MARC

  # A class for writing MARC records as binary MARC (ISO 2709)
  #
  # == Too-long records
  #
  # The MARC binary format only allows records that are total 99999 bytes long,
  # due to size of a length field in the record.
  #
  # By default, the Writer will raise a MARC::Exception when encountering
  # in-memory records that are too long to be legally written out as ISO 2709
  # binary.

  # However, if you set `allow_oversized` to true, then the Writer will
  # write these records out anyway, filling in any binary length/offset slots
  # with all 0's, if they are not wide enough to hold the true value.
  # While these records are illegal, they can still be read back in using
  # the MARC::ForgivingReader, as well as other platform MARC readers
  # in tolerant mode.
  #
  # If you set `allow_oversized` to false on the Writer, a MARC::Exception
  # will be raised instead, if you try to write an oversized record.
  #
  #    writer = Writer.new(some_path)
  #    writer.allow_oversized = true
  class Writer
    attr_accessor :allow_oversized

    # the constructor which you must pass a file path
    # or an object that responds to a write message

    def initialize(file)
      if file.is_a?(String) || file.is_a?(Pathname)
        @fh = File.new(file,"w")
      elsif file.respond_to?('write')
        @fh = file
      else
        raise ArgumentError, "must pass in file name or handle"
      end
      self.allow_oversized = false
    end


    # write a record to the file or handle

    def write(record)
      @fh.write(MARC::Writer.encode(record, self.allow_oversized))
    end


    # close underlying filehandle

    def close
      @fh.close
    end


    # a static method that accepts a MARC::Record object
    # and returns the record encoded as MARC21 in transmission format
    #
    # Second arg allow_oversized, default false, set to true
    # to raise on MARC record that can't fit into ISO 2709. 
    def self.encode(record, allow_oversized = false)
      directory = ''
      fields = ''
      offset = 0
      record.each do |field|

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
        directory += sprintf("%03s", field.tag) + format_byte_count(field_length, allow_oversized, 4) + format_byte_count(offset, allow_oversized)


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
      bytesize = base.respond_to?(:bytesize) ? base.bytesize() : base.length()
      marc[12..16] = format_byte_count(bytesize, allow_oversized)
      

      # update the record length
      bytesize = marc.respond_to?(:bytesize) ? marc.bytesize() : marc.length()
      marc[0..4] = format_byte_count(bytesize, allow_oversized)      

      # store updated leader in the record that was passed in
      record.leader = marc[0..LEADER_LENGTH-1]

      # return encoded marc
      return marc
    end

    # Formats numbers for insertion into marc binary slots.
    # These slots only allow so many digits (and need to be left-padded
    # with spaces to that number of digits). If the number
    # is too big, either an exception will be raised, or
    # we'll return all 0's to proper number of digits.
    #
    # first arg is number, second is boolean whether to allow oversized,
    # third is max digits (default 5)
    def self.format_byte_count(number, allow_oversized, num_digits=5)
      formatted = sprintf("%0#{num_digits}i", number)
      if formatted.length > num_digits
        # uh, oh, we've exceeded our max. Either zero out
        # or raise, depending on settings.
        if allow_oversized
          formatted = sprintf("%0#{num_digits}i", 0)
        else
          raise MARC::Exception.new("Can't write MARC record in binary format, as a length/offset value of #{number} is too long for a #{num_digits}-byte slot.")
        end
      end
      return formatted
    end

  end
end
