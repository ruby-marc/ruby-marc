#marc is a ruby library for reading and writing MAchine Readable Cataloging
#(MARC). More information about MARC can be found at <http://www.loc.gov/marc>.
#
#USAGE 
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
#    record.add_field(MARC::ControlField.new('FMT', 'Book')) # doesn't throw an error


require File.dirname(__FILE__) + '/marc/version'
require File.dirname(__FILE__) + '/marc/constants'
require File.dirname(__FILE__) + '/marc/record'
require File.dirname(__FILE__) + '/marc/datafield'
require File.dirname(__FILE__) + '/marc/controlfield'
require File.dirname(__FILE__) + '/marc/subfield'
require File.dirname(__FILE__) + '/marc/reader'
require File.dirname(__FILE__) + '/marc/writer'
require File.dirname(__FILE__) + '/marc/exception'
require File.dirname(__FILE__) + '/marc/xmlwriter'
require File.dirname(__FILE__) + '/marc/xmlreader'
require File.dirname(__FILE__) + '/marc/dublincore'
require File.dirname(__FILE__) + '/marc/xml_parsers'
