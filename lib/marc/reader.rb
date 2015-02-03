require 'scrub_rb'

# Note: requiring 'marc/marc8/to_unicode' below, in #initialize,
# only when necessary

module MARC
  # A class for reading MARC binary (ISO 2709) files. 
  #
  # == Character Encoding
  #
  # In ruby 1.9+, ruby tags all strings with expected character encodings.
  # If illegal bytes for that character encoding are encountered in certain
  # operations, ruby will raise an exception. If a String is incorrectly
  # tagged with the wrong character encoding, that makes it fairly likely
  # an illegal byte for the specified encoding will be encountered. 
  #
  # So when reading binary MARC data with the MARC::Reader, it's important
  # that you let it know the expected encoding:
  #
  #     MARC::Reader.new("path/to/file.mrc", :external_encoding => "UTF-8")
  #
  # If you leave off 'external_encoding', it will use the ruby environment
  # Encoding.default_external, which is usually UTF-8 but may depend on your
  # environment. 
  #
  # Even if you expect your data to be (eg) UTF-8, it may include bad/illegal
  # bytes. By default MARC::Reader will leave these in the produced Strings,
  # which will probably raise an exception later in your program. Better
  # to catch this early, and ask MARC::Reader to raise immediately on illegal
  # bytes:
  #
  #     MARC::Reader.new("path/to/file.mrc", :external_encoding => "UTF-8", 
  #       :validate_encoding => true)
  #
  # Alternately, you can have MARC::Reader replace illegal bytes
  # with the Unicode Replacement Character, or with a string
  # of your choice (including the empty string, meaning just omit the bad bytes)
  #
  #     MARC::Reader("path/to/file.mrc", :external_encoding => "UTF-8", 
  #        :invalid => :replace)
  #     MARC::Reader("path/to/file.mrc", :external_encoding => "UTF-8", 
  #        :invalid => :replace, :replace => "")
  #
  # If you supply an :external_encoding argument, MARC::Reader will
  # always assume that encoding -- if you leave it off, MARC::Reader
  # will use the encoding tagged on any input you pass in, such
  # as Strings or File handles. 
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
  # === MARC-8
  #
  # The legacy MARC-8 encoding needs to be handled differently, because
  # there is no built-in support in ruby for MARC-8. 
  #
  # You _can_ specify "MARC-8" as an external encoding. It will trigger
  # trans-code to UTF-8 (NFC-normalized) in the internal ruby strings. 
  #
  #     MARC::Reader.new("marc8.mrc", :external_encoding => "MARC-8")
  #
  # For external_encoding "MARC-8", :validate_encoding is always true,
  # there's no way to ignore bad bytes in MARC-8 when transcoding to
  # unicode.  However, just as with other encodings, the 
  # `:invalid => :replace` and `:replace => "string"`
  # options can be used to replace bad bytes instead of raising. 
  #
  # If you want your MARC-8 to be transcoded internally to something
  # other than UTF-8, you can use the :internal_encoding option
  # which works with any encoding in MARC::Reader. 
  #
  #     MARC::Reader.new("marc8.mrc", 
  #       :external_encoding => "MARC-8", 
  #       :internal_encoding => "UTF-16LE")
  #
  # If you want to read in MARC-8 without transcoding, leaving the
  # internal Strings in MARC-8, the only way to do that is with
  # ruby's 'binary' (aka "ASCII-8BIT") encoding, since ruby doesn't
  # know from MARC-8. This will work:
  #
  #     MARC::Reader.new("marc8.mrc", :external_encoding => "binary")
  #
  # Please note that MARC::Reader does _not_ currently have any facilities 
  # for guessing encoding from MARC21 leader byte 9, that is ignored. 
  #
  # === Complete Encoding Options
  #
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
  # === Warning on ruby File's own :internal_encoding, and unsafe transcoding from ruby
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
  #
  # === jruby note
  # In the past, jruby encoding-related bugs have caused problems with
  # our encoding treatments. See for example:
  # https://jira.codehaus.org/browse/JRUBY-6637
  #
  # We recommend using the latest version of jruby, especially
  # at least jruby 1.7.6. 
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
        raise ArgumentError, "must pass in path or file"
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

      # Only pull in the MARC8 translation if we need it, since it's really big
      if @encoding_options[:external_encoding]  == "MARC-8"
        require 'marc/marc8/to_unicode' unless defined? MARC::Marc8::ToUnicode
      end

    end

    # to support iteration:
    #   for record in reader
    #     print record
    #   end
    def each
      unless block_given?
        return self.enum_for(:each)
      else
        until @handle.eof? do
          record = self.decode(@handle)
          if record
            yield record
          else
            break
          end
        end
      end
    end

    # Iterates over each record as a raw String, rather than a decoded
    # MARC::Record
    #
    # This allows for handling encoding exceptions per record (e.g. to log which
    # record caused the error):
    #
    #   reader = MARC::Reader.new("marc_with_some_bad_records.dat",
    #                                 :external_encoding => "UTF-8",
    #                                 :validate_encoding => true)
    #   reader.each_raw do |raw|
    #     begin
    #       record = reader.decode(raw)
    #     rescue Encoding::InvalidByteSequenceError => e
    #       record = MARC::Reader.decode(raw, :external_encoding => "UTF-8",
    #                                         :invalid => :replace)
    #       warn e.message, record
    #     end
    #   end
    #
    # If no block is given, an enumerator is returned
    def each_raw
      unless block_given?
        return self.enum_for(:each_raw)
      else
        while rec_length_s = @handle.read(5)
          # make sure the record length looks like an integer
          rec_length_i = rec_length_s.to_i
          if rec_length_i == 0
            raise MARC::Exception.new("invalid record length: #{rec_length_s}")
          end

          # get the raw MARC21 for a record back from the file
          # using the record length
          raw = rec_length_s + @handle.read(rec_length_i-5)
          yield raw
        end
      end
    end

    # Decodes the given string into a MARC::Record object.
    #
    # Wraps the class method MARC::Reader::decode, using the encoding options of
    # the MARC::Reader instance.
    def decode(marc)
      return MARC::Reader.decode(marc, @encoding_options)
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
      # And now that we've recorded the current encoding, we force
      # to binary encoding, because we're going to be doing byte arithmetic,
      # and want to avoid byte-vs-char confusion.
      if marc.is_a? String
        marc.force_encoding('binary') if marc.respond_to? :force_encoding
        marc = StringIO.new(marc) if marc.is_a? String
      else
        marc = marc.binmode
      end
      record_leader = marc.read(LEADER_LENGTH)

      record_length = record_leader[0..4].to_i
      if record_length == 0 && !params[:forgiving]
        raise MARC::Exception.new("invalid record length: #{record_leader[0..4]}'")
      end
      record = Record.new()
      record.leader = record_leader
      # where the field data starts
      base_address = record_leader[12..16].to_i
      num_fields = (base_address - LEADER_LENGTH) / DIRECTORY_ENTRY_LENGTH
      buf5 = '     ' # buffer for transient data in parsing
      entries = Array.new(num_fields) do
        [marc.read(3), marc.read(4,buf5).to_i, marc.read(5,buf5).to_i]
      end
      raise "missing field terminator after directory" unless marc.read(1,buf5).eql? END_OF_FIELD
      # when operating in forgiving mode we just split on end of
      # field instead of using calculated byte offsets from the
      # directory
      if params[:forgiving]
        entries.each do |entry|
          marc_field_data = marc.gets(END_OF_FIELD)
          add_field(record, entry[0], marc_field_data, params)
        end
      else
        offset = base_address
        # get the byte offsets from the record directory
        entries.sort! {|a,b| a[2] <=> b[2]}.each do |entry|
          entry_offset = entry[2] + base_address
          raise MARC::Exception.new('overlapping entries') if offset > entry_offset
          raise MARC::Exception.new('entry points past end of record') if (entry_offset + entry[1]) > record_length
          if entry_offset > offset
            marc.seek(entry_offset - offset, IO::SEEK_CUR)
            offset = entry_offset
          end
          marc_field_data = marc.read(entry[1])
          offset += marc_field_data.length
          add_field(record, entry[0], marc_field_data, params)
        end
      end

      # discard any remaining data including the record terminator
      marc.gets(END_OF_RECORD)

      return record
    end

    def self.add_field(record, tag, field_data, params)
      # remove end of field
      field_data.delete!(END_OF_FIELD)
      # add a control field or data field
      if MARC::ControlField.control_tag?(tag)
        field_data = MARC::Reader.set_encoding( field_data , params)
        record.append(MARC::ControlField.new(tag,field_data))
      else

        # get all subfields
        subfields = field_data.split(SUBFIELD_INDICATOR)

        # must have at least 2 elements (indicators, and 1 subfield)
        # TODO some sort of logging?
        return if subfields.length() < 2

        # get indicators
        indicators = MARC::Reader.set_encoding( subfields.shift(), params)
        subfields = subfields.collect do |data|
          data = MARC::Reader.set_encoding( data, params )
          MARC::Subfield.new(data.slice!(0,1),data)
        end
        field = MARC::DataField.new(tag,indicators[0,1],indicators[1,1], *subfields)

        # add the field to the record
        record.append(field)
      end
    end
    # input passed in probably has 'binary' encoding. 
    # We'll set it to the proper encoding, and depending on settings, optionally
    # * check for valid encoding
    #   * raise if not valid
    #   * or replace bad bytes with replacement chars if not valid
    # * transcode from external_encoding to internal_encoding
    #
    # Special case for encoding "MARC-8" -- will be transcoded to
    # UTF-8 (then further transcoded to external_encoding, if set).
    # For "MARC-8", validate_encoding is always true, there's no way to
    # ignore bad bytes. 
    #
    # Params options:
    # 
    #  * external_encoding: what encoding the input is expected to be in  
    #  * validate_encoding: if true, will raise if an invalid encoding
    #  * invalid:  if set to :replace, will replace bad bytes with replacement
    #              chars instead of raising. 
    #  * replace: Set replacement char for use with 'invalid', otherwise defaults
    #             to unicode replacement char, or question mark. 
    def self.set_encoding(str, params)
      if str.respond_to?(:force_encoding)
        if params[:external_encoding]
          if params[:external_encoding] == "MARC-8"
            transcode_params = [:invalid, :replace].each_with_object({}) { |k, hash| hash[k] = params[k] if params.has_key?(k) }
            str = MARC::Marc8::ToUnicode.new.transcode(str, transcode_params)
          else
            str = str.force_encoding(params[:external_encoding])
          end
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
          str = str.encode(params[:internal_encoding], params)
        elsif (params[:invalid] || params[:replace] || (params[:validate_encoding] == true))

          if params[:validate_encoding] == true && ! str.valid_encoding?
            raise  Encoding::InvalidByteSequenceError.new("invalid byte in string for source encoding #{str.encoding.name}")
          end
          if params[:invalid] == :replace
            str = str.scrub(params[:replace])
          end          
        end          
      end
      return str
    end                
  end




  # Like Reader ForgivingReader lets you read in a batch of MARC21 records
  # but it does not use record lengths and field byte offets found in the
  # leader and directory. It is not unusual to run across MARC records
  # which have had their offsets calculated wrong. In situations like this
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
      until @handle.eof? do
        begin
          record = MARC::Reader.decode(@handle, @encoding_options.merge(:forgiving => true))
          yield record
        rescue StandardError => e
          # caught exception just keep barrelling along
          # TODO add logging
        end
      end
    end
  end
end