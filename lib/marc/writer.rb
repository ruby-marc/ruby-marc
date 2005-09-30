module MARC

    # A class for writing MARC records.

    class Writer

        # the constructor which you must pass a file path
        # or an object that responds to a write message

        def initialize(file)
            if file.class == String
                @fh = File.new(file)
            elsif file.respond_to?(file)
                @fh = file
            else
                throw "must pass in file name or handle"
            end
        end

        # write a record to the file or handle

        def write(record)
            @fh.write(record.encode)
        end

    end

end
