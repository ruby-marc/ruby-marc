module MARC

    class Reader
        include Enumerable

        # The constructor which you may pass either a path 
        #
        #     reader = MARC::Reader.new('marc.dat')
        # 
        # or, if it's more convenient a File object:
        #
        #     fh = File.new('marc.dat')
        #     reader = MARC::Reader.new(fh)
        #
        # or really any object that responds to read(n).
        
        def initialize(file)
            if file.class == String:
                @handle = File.new(file)
            elsif file.respond_to?("read", 5)
                @handle = file
            else
                throw "must pass in path or file"
            end
        end

        # to support iteration:
        #     for record in reader
        #         print record
        #     end
        #
        # and even searching:
        #     record.find { |f| f['245'] =~ /Huckleberry/ }

        def each 
            # while there is data left in the file
            while length = @handle.read(5)

                # get the raw MARC21 for a record back from the file
                # using the record length
                raw = length + @handle.read(length.to_i-5)

                # create a record from the data and return it
                record = MARC::Record.new_from_marc(raw)
                yield record 
            end
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
            elsif file.class == File
                @handle = file
            else
                throw "must pass in path or File object"                
            end
        end


        def each 
            @handle.each_line(MARC::MARC21::END_OF_RECORD) do |raw| 
                record = MARC::Record.new_from_marc(raw, :forgiving => true)
                yield record 
            end
        end

    end


end
