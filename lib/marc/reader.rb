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

end
