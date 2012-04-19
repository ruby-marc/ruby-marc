marc is a ruby library for reading and writing MAchine Readable Cataloging
(MARC). More information about MARC can be found at <http://www.loc.gov/marc>.

## Usage 

    require 'marc'
  
    # reading records from a batch file
    reader = MARC::Reader.new('marc.dat')
    for record in reader
      # print out field 245 subfield a
      puts record['245']['a']
    end
  
    # creating a record 
    record = MARC::Record.new()
    record.append(MARC::DataField.new('100', '0',  ' ', ['a', 'John Doe']))
  
    # writing a record
    writer = MARC::Writer.new('marc.dat')
    writer.write(record)
    writer.close()
  
    # writing a record as XML
    writer = MARC::XMLWriter.new('marc.xml')
    writer.write(record)
    writer.close()
    
    # encoding a record
    MARC::Writer.encode(record) # or record.to_marc

MARC::Record provides `#to_hash` and `#from_hash` implementations that deal in ruby
hash's that are compatible with the 
[marc-in-json](http://dilettantes.code4lib.org/blog/2010/09/a-proposal-to-serialize-marc-in-json/)
serialization format. You are responsible for serializing the hash to/from JSON yourself. 

## Installation

    gem install marc

Or if you're using bundler, add to your Gemfile

    gem 'marc'
  
## Miscellany 

Source code at: https://github.com/ruby-marc/ruby-marc/

Find generated API docs at: http://rubydoc.info/gems/marc/frames

Run automated tests in source with `rake test`. 

Developers, release new version of gem to rubygems with `rake release` 
(bundler-supplied task). Note that one nice thing this will do is automatically
tag the version in git, very important for later figuring out what's going on.

Please send bugs, requests and comments to Code4Lib Mailing list (https://listserv.nd.edu/cgi-bin/wa?A0=CODE4LIB). 

## Authors

Kevin Clarke <ksclarke@gmail.com>
Bill Dueber <bill@dueber.com>
William Groppe <will.groppe@gmail.com>
Ross Singer <rossfsinger@gmail.com>
Ed Summers <ehs@pobox.com>
