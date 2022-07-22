# marc is a ruby library for reading and writing MAchine Readable Cataloging
# (MARC). More information about MARC can be found at <http://www.loc.gov/marc>.
#
# USAGE
#
#    require 'marc'
#
#    # reading records from a batch file
#    reader = MARC::Reader.new('marc.dat')
#    for record in reader
#      puts record['245']['a']
#    end
#
#    # creating a record
#    record = MARC::Record.new()
#    record.add_field(MARC::DataField.new('100', '0',  ' ', ['a', 'John Doe']))
#
#    # writing a record
#    writer = MARC::Writer.new('marc.dat')
#    writer.write(record)
#    writer.close()
#
#    # writing a record as XML
#    writer = MARC::XMLWriter.new('marc.xml')
#    writer.write(record)
#    writer.close()
#
#    # Deal with non-standard control field tags
#    MARC::Field.control_tags << 'FMT'
#    record = MARC::Record.new()
#    record.add_field(MARC::ControlField.new('FMT', 'Book')) # doesn't raise an error

require_relative "marc/version"
require_relative "marc/constants"
require_relative "marc/record"
require_relative "marc/datafield"
require_relative "marc/controlfield"
require_relative "marc/subfield"
require_relative "marc/reader"
require_relative "marc/writer"
require_relative "marc/exception"
require_relative "marc/xmlwriter"
require_relative "marc/unsafe_xmlwriter"
require_relative "marc/xmlreader"
require_relative "marc/dublincore"
require_relative "marc/xml_parsers"
