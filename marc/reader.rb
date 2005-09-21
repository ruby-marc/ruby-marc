module MARC

    class Reader
        include Enumerable

        def initialize(file)
        end

        def each 
            yield MARC::Record.new()
        end

    end

end
