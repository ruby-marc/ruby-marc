module MARC

  class Reader
    include Enumerable

    # The constructor which you may pass either a path
    #
    #   reader = MARC::Reader.new('marc.dat')
    #
    # or, if it's more convenient a File object:
    #
    #   fh = File.new('marc.dat')
    #   reader = MARC::Reader.new(fh)
    #
    # or really any object that responds to read(n)
    #
    #   # marc is a string with a bunch of records in it
    #   reader = MARC::Reader.new(StringIO.new(marc))
    #
    # If your data have non-standard control fields in them
    # (e.g., Aleph's 'FMT') you need to add them specifically
    # to the MARC::ControlField.control_tags Set object
    #
    #   MARC::ControlField.control_tags << 'FMT'
    #
    # Also, if your data encoded with non ascii/utf-8 encoding
    # (for ex. when reading RUSMARC data) and you use ruby 1.9
    # you can specify source data encoding with an option. 
    #
    #   reader = MARC::Reader.new('marc.dat', :external_encoding => 'cp866')
    #
    # or, you can pass IO, opened in the corresponding encoding
    #
    #   reader = MARC::Reader.new(File.new('marc.dat', 'r:cp866'))
    def initialize(file, options = {})      
      @encoding_options = {}
      # all can be nil
      [:internal_encoding, :external_encoding, :invalid, :replace].each do |key|
        @encoding_options[key] = options[key] if options.has_key?(key)
      end
            
      if file.is_a?(String)
        @handle = File.new(file)
      elsif file.respond_to?("read", 5)
        @handle = file
      else
        throw "must pass in path or file"
      end
      
      if (! @encoding_options[:external_encoding] ) && @handle.respond_to?(:external_encoding)
        # use file encoding only if we didn't already have an explicit one,
        # explicit one takes precedence. 
        #
        # Note, please don't use ruby's own internal_encoding transcode
        # with binary marc data, the transcode can mess up the byte count
        # and make it unreadable. 
        @encoding_options[:external_encoding] ||= @handle.external_encoding
      end      
    end

    # to support iteration:
    #   for record in reader
    #     print record
    #   end
    def each
      # while there is data left in the file
      while rec_length_s = @handle.read(5)
        # make sure the record length looks like an integer
        rec_length_i = rec_length_s.to_i
        if rec_length_i == 0
          raise MARC::Exception.new("invalid record length: #{rec_length_s}")
        end

        # get the raw MARC21 for a record back from the file
        # using the record length
        raw = rec_length_s + @handle.read(rec_length_i-5)


        # create a record from the data and return it
        #record = MARC::Record.new_from_marc(raw)
        record = MARC::Reader.decode(raw, @encoding_options)
        yield record
      end
    end


    # A static method for turning raw MARC data in transission
    # format into a MARC::Record object.
    # First argument is a String
    # options include:
    #   [:external_encoding]  encoding of MARC record data values
    #   [:forgiving]          needs more docs, true is some kind of forgiving 
    #                         of certain kinds of bad MARC. 
    def self.decode(marc, params={})
      if params.has_key?(:encoding)
        $stderr.puts "DEPRECATION WARNING: MARC::Reader.decode :encoding option deprecated, please use :external_encoding"
        params[:external_encoding] = params.delete(:encoding)
      end
      
      if (! params.has_key? :external_encoding ) && marc.respond_to?(:encoding)
        # If no forced external_encoding giving, respect the encoding
        # declared on the string passed in. 
        params[:external_encoding] = marc.encoding
      end
      
      record = Record.new()
      record.leader = marc[0..LEADER_LENGTH-1]

      # where the field data starts
      base_address = record.leader[12..16].to_i

      # get the byte offsets from the record directory
      directory = marc[LEADER_LENGTH..base_address-1]

      throw "invalid directory in record" if directory == nil

      # the number of fields in the record corresponds to
      # how many directory entries there are
      num_fields = directory.length / DIRECTORY_ENTRY_LENGTH

      # when operating in forgiving mode we just split on end of
      # field instead of using calculated byte offsets from the
      # directory
      if params[:forgiving]
        all_fields = marc[base_address..-1].split(END_OF_FIELD)
      else
        mba =  marc.bytes.to_a
      end

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
          field_data = mba[field_start..field_end].pack("c*")
        end

        # remove end of field
        field_data.delete!(END_OF_FIELD)

        if field_data.respond_to?(:force_encoding)
          if params[:external_encoding]
            field_data = field_data.force_encoding(params[:external_encoding])
          end     
          
          # If we don't check this now to raise a InvalidByteSequenceError,
          # bad bytes will trigger ArgumentErrors from arbitrary part
          # of the ruby_marc stack _anyway_, we got to check now for
          # a predictable erorr message. 
          # pass on params for :replace and :invalid options. 
          field_data = MARC::Reader.validate_encoding(field_data,  params)
          
          if params[:internal_encoding]
            field_data = field_data.encode(params[:internal_encoding])
          end
          
          
        end
        # add a control field or data field
        if MARC::ControlField.control_tag?(tag)
          record.append(MARC::ControlField.new(tag,field_data))
        else
          field = MARC::DataField.new(tag)

          # get all subfields
          subfields = field_data.split(SUBFIELD_INDICATOR)

          # must have at least 2 elements (indicators, and 1 subfield)
          # TODO some sort of logging?
          next if subfields.length() < 2

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
            
    # Pass in a string, will raise an Encoding::InvalidByteSequenceError
    # if it contains an invalid byte for it's encoding; otherwise
    # returns an equivalent string. Surprisingly not built into 
    # ruby 1.9.3 (yet?). https://bugs.ruby-lang.org/issues/6321
    #
    # The InvalidByteSequenceError will NOT be filled out
    # with the usual error metadata, sorry. 
    #
    # OR, like String#encode, pass in option `:invalid => :replace`
    # to replace invalid bytes with a replacement string in the
    # returned string.  Pass in the
    # char you'd like with option `:replace`, or will, like String#encode
    # use the unicode replacement char if it thinks it's a unicode encoding,
    # else ascii '?'.
    #
    # in any case, method will raise, or return a new string
    # that is #valid_encoding?
    def self.validate_encoding(str, options = {})
      return str unless str.respond_to?(:encoding)
      
      str.chars.collect do |c|
        if c.valid_encoding?
          c
        else
          unless options[:invalid] == :replace
            # it ought to be filled out with all the metadata
            # this exception usually has, but what a pain!
            # Why isn't ruby doing this for us?
            raise  Encoding::InvalidByteSequenceError.new("#{c.inspect} in #{c.encoding.name}")
          else
            options[:replace] || (
             # surely there's a better way to tell if
             # an encoding is a 'Unicode encoding form'
             # than this? What's wrong with you ruby 1.9?
             str.encoding.name.start_with?('UTF') ?
                "\uFFFD" :
                "?" )
          end
        end
      end.join
    end
    
  end




  # Like Reader ForgivingReader lets you read in a batch of MARC21 records
  # but it does not use record lengths and field byte offets found in the
  # leader and directory. It is not unusual to run across MARC records
  # which have had their offsets calcualted wrong. In situations like this
  # the vanilla Reader may fail, and you can try to use ForgivingReader.

  # The one downside to this is that ForgivingReader will assume that the
  # order of the fields in the directory is the same as the order of fields
  # in the field data. Hopefully this will be the case, but it is not
  # 100% guranteed which is why the normal behavior of Reader is encouraged.

  class ForgivingReader
    include Enumerable

    def initialize(file)
      if file.class == String
        @handle = File.new(file)
      elsif file.respond_to?("read", 5)
        @handle = file
      else
        throw "must pass in path or File object"
      end
    end


    def each
      @handle.each_line(END_OF_RECORD) do |raw|
        begin
          record = MARC::Reader.decode(raw, :forgiving => true)
          yield record
        rescue StandardError => e
          # caught exception just keep barrelling along
          # TODO add logging
        end
      end
    end
  end
end
