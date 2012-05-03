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
    
## Character Encodings

Dealing with character encoding issues is one of the most confusing programming areas in general, and dealing with MARC (esp 'binary' ISO 2709 marc) can make it even more confusing.   

In ruby 1.8, if you get your character encodings wrong, you may find what look like garbage characters in your output. In ruby 1.9, you may also cause exceptions to be raised in your code.  ruby-marc as of 0.5.0 has a fairly complete and consistent featureset for helping you deal with character encodings in 'binary' MARC.  

There are no tools in ruby for transcoding or dealing with the 'marc8' encoding, used in Marc21 in the US and other countries.  If you have to deal with MARC with marc8 encoding, your best bet is using an external tool to convert between MARC8 and UTF8 before the ruby app even sees it. [MarcEdit](http://people.oregonstate.edu/~reeset/marcedit/html/index.php), [yaz-marcdump command line tool](http://www.indexdata.com/yaz), [Marc4J java library](http://marc4j.tigris.org/)

### 'binary' ISO 2709 MARC

The Marc binary (ISO 2709) Reader (MARC::Reader) has some features for helping you deal with character encodings in ruby 1.9. It should often do the right thing, especially if you are working only in unicode. See documentation in that class for details, including additional features you can use.   Note it does NOT currently determine encoding based on internal leader bytes in the marc file.   

The MARC binary Writer (MARC::Writer) does not have any such features -- it's up to you the developer to make sure you create MARC::Records with consistent and expected char encodings, although MARC::Writer will write out a legal ISO 2709 either way, it just might have corrupted encodings.

#### jruby note

Note all of our char encoding tests currently pass on jruby in ruby 1.9 mode; if you are using binary MARC records in a non-UTF8 encoding, you may have trouble in jruby. We believe it's a jruby bug. 


### xml or json

For XML or json use, things should probably work right if your input is in UTF-8, but this hasn't been extensively tested. Feel free to file issues if you run into any. 
  
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
