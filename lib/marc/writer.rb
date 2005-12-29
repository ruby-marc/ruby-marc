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
            @fh.write(record.to_marc)
        end


        # close underlying filehandle

        def close
            @fh.close
        end

    end

end
