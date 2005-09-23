module MARC

    class Reader
        include Enumerable

        def initialize(file)
            @handle = File.new(file)
        end

        def each 
            # while there is data left in the file
            while length = @handle.read(5)

                # get the raw MARC21 for a record back from the file
                # using the record length
                raw = length + @handle.read(length.to_i-5)

                # create a record from the data and return it
                record = MARC::Record.decode(raw)
                yield record 
            end
        end

    end

end
