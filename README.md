[![Gem Version](https://badge.fury.io/rb/marc.png)](http://badge.fury.io/rb/marc)
![Build Status](https://github.com/ruby-marc/ruby-marc/workflows/CI/badge.svg) | 

marc is a ruby library for reading and writing MAchine Readable Cataloging
(MARC). More information about MARC can be found at <http://www.loc.gov/marc>.

## Usage 

    require 'marc'
  
    # reading records from a batch file
    reader = MARC::Reader.new('marc.dat', :external_encoding => "MARC-8")
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
[marc-in-json](https://rossfsinger.com/blog/2010/09/a-proposal-to-serialize-marc-in-json/)
serialization format. You are responsible for serializing the hash to/from JSON yourself. 

## Installation

    gem install marc

Or if you're using bundler, add to your Gemfile

    gem 'marc'
    
## Character Encodings in 'binary' ISO-2709 MARC

The Marc binary (ISO 2709) Reader (MARC::Reader) has some features for helping you deal with character encodings in ruby 1.9. It is always recommended to supply an explicit :external_encoding option to MARC::Reader; either any valid ruby encoding, _or_ the string "MARC-8".  MARC-8 input will by default be transcoded to a UTF-8 internal representation.

MARC::Reader does _not_ currently have any facilities for guessing encoding from MARC21 leader byte 9, that is
ignored. 

Consult the MARC::Reader class docs for a more complete discussion and range of options. 

The MARC binary Writer (MARC::Writer) does not have any encoding-related features -- it's up to you the developer to make sure you create MARC::Records with consistent and expected char encodings, although MARC::Writer will write out a legal ISO 2709 either way, it just might have corrupted encodings.

When parsing MARCXML _with Nokogiri as your XML parser implementation_ up to
and including version `1.0.2` of this gem, if the XML was badly formed, parsing
would stop and no error would be reported to your code.  

If you are using a version > `1.0.2` of `ruby-marc` with MRI + Nokogiri, XML
syntax errors will be thrown (and you may need to adjust your code to account
for this).  *JRuby users*: If you are using a version later than `1.0.2` and
using Nokogiri as an XML parser with JRuby as your ruby implementation, XML
syntax errors will still be ignored unless you have Nokogiri version `1.10.2`
or later.

## JRubySTAXReader caveats

- Under Java 9+, MARC::JRubySTAXReader requires adding the following to `JAVA_OPTS`
  in order to work around [Java module system](https://openjdk.java.net/jeps/261) 
  restrictions:

  ```sh
  --add-opens java.xml/com.sun.org.apache.xerces.internal.impl=org.jruby.dist
  ```

- MARC::JRubySTAXReader is deprecated and will be removed in a future version of
  `ruby-marc`. Please use MARC::JREXMLReader or MARC::NokogiriReader instead.

## Miscellany 

Source code at: https://github.com/ruby-marc/ruby-marc/

Find generated API docs at: http://rubydoc.info/gems/marc/frames

Run automated tests in source with `rake test`. 

Developers, release new version of gem to rubygems with `rake release` 
(bundler-supplied task). Note that one nice thing this will do is automatically
tag the version in git, very important for later figuring out what's going on.

## Authors

Kevin Clarke <ksclarke@gmail.com>
Bill Dueber <bill@dueber.com>
William Groppe <will.groppe@gmail.com>
Ross Singer <rossfsinger@gmail.com>
Ed Summers <ehs@pobox.com>
