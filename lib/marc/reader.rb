module MARC
  # A class for reading MARC binary (ISO 2709) files. 
  #
  # == Character Encoding
  #
  # In ruby 1.8, if you mess up your character encodings, you may get
  # garbage bytes. MARC::Reader takes no special action to determine or
  # correct character encodings in ruby 1.8. 
  #
  # In ruby 1.9, if character encodings get confused, you will likely get an 
  # exception raised at some point, either from inside MARC::Reader or in your 
  # own code. If your marc records are not in UTF-8, you will have to make sure
  # MARC::Reader knows what character encoding to expect. For UTF-8, normally
  # it will just work. 
  #
  # Note that if your source data includes invalid illegal characters
  # for it's encoding, while it _may_ not cause MARC::Reader to raise an
  # exception, it will likely result in an exception at a later point in
  # your own code. You can ask MARC::Reader to remove invalid bytes from data, 
  # see :invalid and :replace options below. 
  #
  # In ruby 1.9, it's important strings are tagged with their proper encoding.
  # **MARC::Reader does _not_ at present look inside the MARC file to see what
  # encoding it claims for itself** -- real world MARC records are so unreliable
  # here as to limit utility; and we have international users and international
  # MARC uses several conventions for this. Instead, MARC::Reader uses ordinary
  # ruby conventions.  If your data is in UTF-8, it'll probably Just Work, 
  # otherwise you simply have to tell MARC::Reader what the source encoding is:
  #
  #     Encoding.default_external # => usually "UTF-8" for most people
  #     # marc data will be considered UTF-8, as per Encoding.default_external
  #     MARC::Reader.new("path/to/file.marc")
  #
  #     # marc data will have same encoding as string.encoding:
  #     MARC::Reader.decode( string )
  #
  #     # Same, values will have encoding of string.encoding:
  #     MARC::Reader.new(StringIO.new(string)) 
  #
  #     # data values will have cp866 encoding, per external_encoding of
  #     # File object passed in
  #     MARC::Reader.new(File.new("myfile.marc", "r:cp866"))
  #
  #     # explicitly tell MARC::Reader the encoding
  #     MARC::Reader.new("myfile.marc", :external_encoding => "cp866")  
  #
  # One way or another, you have to tell MARC::Reader what the external
  # encoding is, if it's not the default for your system (usually UTF-8).
  # It won't guess from internal MARC leader etc. 
  #
  # == Additional Options
  # These options can all be used on MARC::Reader.new _or_ MARC::Reader.decode
  # to specify external encoding, ask for a transcode to a different
  # encoding on read, or validate or replace bad bytes in source. 
  #
  # [:external_encoding]
  #    What encoding to consider the MARC record's values to be in. This option
  #    takes precedence over the File handle or String argument's encodings. 
  # [:internal_encoding]
  #    Ask MARC::Reader to transcode to this encoding in memory after reading
  #    the file in. 
  # [:validate_encoding]
  #    If you pass in `true`, MARC::Reader will promise to raise an Encoding::InvalidByteSequenceError
  #    if there are illegal bytes in the source for the :external_encoding. There is
  #    a performance penalty for this check. Without this option, an exception
  #    _may_ or _may not_ be raised, and whether an exception or raised (or 
  #    what class the exception has) may change in future ruby-marc versions
  #    without warning. 
  # [:invalid]
  #    Just like String#encode, set to :replace and any bytes in source data
  #    illegal for the source encoding will be replaced with the unicode 
  #    replacement character (when in unicode encodings), or else '?'. Overrides
  #    :validate_encoding. This can help you sanitize your input and
  #    avoid ruby "invalid UTF-8 byte" exceptions later. 
  # [:replace]
  #    Just like String#encode, combine with `:invalid=>:replace`, set
  #    your own replacement string for invalid bytes. You may use the
  #    empty string to simply eliminate invalid bytes. 
  #
  # == Warning on ruby File's own :internal_encoding, and unsafe transcoding from ruby
  #
  # Be careful with using an explicit File object with the File's own 
  # :internal_encoding set -- it can cause ruby to transcode your data 
  # _before_ MARC::Reader gets it, changing the bytecount and making the 
  # marc record unreadable in some cases. This
  # applies to Encoding.default_encoding too!
  #
  #    # May in some cases result in unreadable marc and an exception 
  #    MARC::Reader.new(  File.new("marc_in_cp866.mrc", "r:cp866:utf-8") )
  #
  #    # May in some cases result in unreadable marc and an exception
  #    Encoding.default_internal = "utf-8"
  #    MARC::Reader.new(  File.new("marc_in_cp866.mrc", "r:cp866") )
  #
  #    # However this shoudl be safe:
  #    MARC::Reader.new(  "marc_in_cp866.mrc", :external_encoding => "cp866")
  #
  #    # And this shoudl be safe, if you do want to transcode:
  #    MARC::Reader.new(  "marc_in_cp866.mrc", :external_encoding => "cp866",
  #       :internal_encoding => "utf-8")
  #
  #    # And this should ALWAYS be safe, with or without an internal_encoding
  #    MARC::Reader.new( File.new("marc_in_cp866.mrc", "r:binary:binary"),
  #       :external_encoding => "cp866",
  #       :internal_encoding => "utf-8")
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
      [:internal_encoding, :external_encoding, :invalid, :replace, :validate_encoding].each do |key|
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
        marc_field_data = marc[base_address..-1]
        # It won't let us do the split on bad utf8 data, but
        # we haven't yet set the 'proper' encoding or used
        # our correction/replace options. So call it binary for now.
        marc_field_data.force_encoding("binary") if marc_field_data.respond_to?(:force_encoding)
        
        all_fields = marc_field_data.split(END_OF_FIELD)
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
          
          # If we're transcoding anyway, pass our invalid/replace options
          # on to String#encode, which will take care of them -- or raise
          # with illegal bytes without :replace=>:invalid. 
          #
          # If we're NOT transcoding, we need to use our own pure-ruby
          # implementation to do invalid byte replacements. OR to raise
          # a predicatable exception iff :validate_encoding, otherwise
          # for performance we won't check, and you may or may not
          # get an exception from inside ruby-marc, and it may change
          # in future implementations. 
          if params[:internal_encoding]
            field_data = field_data.encode(params[:internal_encoding], params)
          elsif (params[:invalid] || params[:replace] || (params[:validate_encoding] == true))
            field_data = MARC::Reader.validate_encoding(field_data,  params)
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
  #
  # The one downside to this is that ForgivingReader will assume that the
  # order of the fields in the directory is the same as the order of fields
  # in the field data. Hopefully this will be the case, but it is not
  # 100% guranteed which is why the normal behavior of Reader is encouraged.
  #
  # **NOTE**: ForgivingReader _may_ have unpredictable results when used
  # with marc records with char encoding other than system default (usually
  # UTF8), _especially_ if you have Encoding.default_internal set. 
  #
  # Implemented a sub-class of Reader over-riding #each, so we still
  # get DRY Reader's #initialize with proper char encoding options
  # and handling. 
  class ForgivingReader < Reader

    def each
      @handle.each_line(END_OF_RECORD) do |raw|
        begin
          record = MARC::Reader.decode(raw, @encoding_options.merge(:forgiving => true))
          yield record
        rescue StandardError => e
          # caught exception just keep barrelling along
          # TODO add logging
        end
      end
    end
  end
end
