[![Gem Version](https://badge.fury.io/rb/marc.png)](http://badge.fury.io/rb/marc)
![Build Status](https://github.com/ruby-marc/ruby-marc/workflows/CI/badge.svg)
|

marc is a ruby library for reading and writing MAchine Readable Cataloging
(MARC). More information about MARC can be found at <http://www.loc.gov/marc>.

## Usage

### Basics

```ruby

reader = MARC::Reader.new("myfile.mrc")
reader.each do |record|
  first_245 = record["245"] #=> #<MARC::DataField...>
  first_245.to_s #=> "245 04 $a The Texas ranger $h [sound recording] / $c Sung by Beale D. Taylor. "
  first_245.value #=> "The Texas ranger[sound recording] /Sung by Beale D. Taylor."
  first_245.codes #=> ["a", "h", "c"]
  first_245["a"] #=> "The Texas ranger"
  
  # A record is an enumerable over its fields and thus can use things like
  # #each, #select, #find, etc.
  
  subject_fields = record.select{|f| f.tag =~ /\A6/}
  
  # Get author fields by supplying a list of tags
  record.fields.each_by_tag(["100", "110", "111"]) do |field|
    puts field.value
  end
end
```


### Reading / Writing MARC21 binary data

```ruby
require 'marc'

# marc21 binary format uses MARC::Reader and MARC::Writer

reader = MARC::Reader.new('marc.dat')
reader.each do |record|
  title = record["245"].value
  puts title
end
```

If you know you have another encoding, you can specify it

```ruby
reader = MARC::Reader.new("marc.dat", external_encoding: "MARC-8")
```

While generally used with files, you can also give a reader an IO object
(usually an already-opened file or a StringIO object)

```ruby
marc_data = File.open("marc.dat")
reader = MARC::Reader.new(marc_data)
```

Similarly, you can write to either a file or an IO-like object

```ruby
writer = MARC::Writer.new("myfile.dat")
# writer = MARC::Writer.new(Zlib::GzipWriter.open("myfile.dat.gz"))

myrecords.each do |rec|
  writer.write(rec)
end
writer.close
```

### Reading/Writing marc-in-json

[marc-in-json](https://rossfsinger.com/blog/2010/09/a-proposal-to-serialize-marc-in-json/)
is a simple hash-based serialization format for MARC, often used with the
[jsonl](https://jsonlines.org/) (aka jsonlines or newline-delimited-json)
file format which puts one json structure on each line.

```ruby

reader = MARC::JSONLReader.new("myfile.jsonl")
writer = MARC::JSONLWriter.new("my_other_file.jsonl")
reader.each do |record|
  writer.write(record)
end
writer.close

```

### Reading/Writing MARC-XML

MARC-XML is an XML-based serialiation format for MARC records. It is,
generally speaking, a lot slower than using MARC21 or marc-in-json.

There are two XML parsers supported going forwards within the ruby-marc code
base: REXML (the first, and for a long time only, ruby XML parser based on
regular expressions) and Nokogiri. Both are compatible with both MRI ("normal") ruby and JRuby.

The Nokogiri parser is about 6x faster than using REXML. See performance
numbers, below.

At one time, it was difficult to install Nokogiri under MRI and impossible
under JRuby. Because of this historical blip, nokogiri is _not_
automatically included when doing `require "marc"` in your code. If you want
to use the Nokogiri-based parser, you must include it explicitly.

```ruby
require "nokogiri"
require "marc"

reader = MARC::XMLReader.new("myfile.xml", parser: "nokogiri")
```

The `parser` argument works as follows:

* if not included, REXML is used
* if "rexml" or "nokogiri", the appropriate parser will be used
* if "magic", the Nokogiri parser will be used if Nokogiri has been loaded;
  otherwise it will fall back to using REXML.

```ruby
# Use the best available
reader = MARC::XMLReader.new("my_file.xml", parser: "magic")
```

### "Self-closing" writers

Much like one can [open a file and have it automatically close at the end 
of a block](https://ruby-doc.org/core-2.5.0/File.html#method-c-open) in 
standard ruby, the various writers will do the same.

```ruby

# separate writer and #close
reader = MARC::Reader.new("my_marc.mrc")
writer = MARC::UnsafeXMLWriter.new("my_marc.xml")
reader.each do |record|
  writer.write(record)
end
writer.close

# "self-closing" equivalent
reader = MARC::Reader.new("my_marc.mrc")
MARC::UnsafeXMLWriter.new("my_marc.xml") do |w|
  reader.each do |record|
    w.write(record)
  end
end
# no need to close the writer here
```

### Serializing a single record

The `MARC::Record` class has utility functions to serialize to the various 
formats. These are generally thin wrappers around the `encode` class
methods (e.g., `MARC::Writer.encode`, `MARC::XMLWriter.encode`, etc.)

* `record.to_marc` will production a marc21 binary string
* `record.to_json_string` returns a string containing the JSON document
  for the marc-in-json serialization
  * This just json-ifies `record.to_hash`, which returns a hash compatible 
    with the marc-in-json format.
* `record.to_xml_string` returns the actual XML string, with the following 
  options:
  * `include_namespace: true` (default: `true`) will include the MARC namespace 
    attributes
  * `fast_but_unsafe: true` (default: `false`) will use the much faster 
    `MARC::UnsafeXMLWriter` code, which produces the XML by string 
    concatenation. See that class for more information, but in general, if 
    your MARC isn't wildly invalid, it works fine and is roughly 15x faster. 
    The default (REXML) simply does `record.to_xml.to_s`

Note that * `record.to_xml`, for historical reasons, returns an REXML document of
the XML serialization and _not_ an XML string as one might expect. 


## Benchmarking reading MARC in various formats

A simple benchmark run on a single thread on a 2017-era x64 Macintosh 
gives the numbers below. 

```
With mri 3.1.0  and  jruby 9.3.6.0	

Format    Implementation  Ruby  r/sec  x Slower compared to fastest  
===================================================================
jsonl     stdlib JSON     mri   6512  1.0  
jsonl     O j             mri   6199  1.0  
marc21    MARC::Reader    mri   2889  2.3  
marc-xml  Nokogiri        mri   1451  4.6  
marc-xml  REXML           mri   239   28.0  

marc21    MARC::Reader    jruby  5455  1.2  
jsonl     stdlib JSON     jruby  5437  1.2  
marc-xml  Nokogiri        jruby  1631  4.1  
marc-xml  REXML           jruby  253   26.5  

```

Note especially that if you're using MARC-XML, Nokogiri will read in
records 4-5 times faster.

## Character Encoding issues

The Marc binary (ISO 2709) Reader (MARC::Reader) has some features for helping
you deal with character encodings in ruby 1.9. It is always recommended to
supply an explicit :external_encoding option to MARC::Reader; either any valid
ruby encoding, _or_ the string "MARC-8".  
MARC-8 input will by default be transcoded to a UTF-8 internal representation.

MARC::Reader does _not_ currently have any facilities for guessing encoding
from MARC21 leader byte 9, that is ignored.

Consult the MARC::Reader class docs for a more complete discussion and range
of options.

The MARC binary Writer (MARC::Writer) does not have any encoding-related
features -- it's up to you the developer to make sure you create MARC::Records
with consistent and expected char encodings, although MARC::Writer will write
out a legal ISO 2709 either way, it just might have corrupted encodings.

When parsing MARCXML _with Nokogiri as your XML parser implementation_ up to
and including version `1.0.2` of this gem, if the XML was badly formed,
parsing would stop and no error would be reported to your code.

If you are using a version > `1.0.2` of `ruby-marc` with MRI + Nokogiri, XML
syntax errors will be thrown (and you may need to adjust your code to account
for this).  *JRuby users*: If you are using a version later than `1.0.2` and
using Nokogiri as an XML parser with JRuby as your ruby implementation, XML
syntax errors will still be ignored unless you have Nokogiri version `1.10.2`
or later.

## JRubySTAXReader caveats

NOTE: The JRubyStaxReader is deprecated. Nokogiri should be used instead.

- Under Java 9+, MARC::JRubySTAXReader requires adding the following
  to `JAVA_OPTS`
  in order to work
  around [Java module system](https://openjdk.java.net/jeps/261)
  restrictions:

  ```sh
  --add-opens java.xml/com.sun.org.apache.xerces.internal.impl=org.jruby.dist
  ```

- MARC::JRubySTAXReader is deprecated and will be removed in a future version
  of
  `ruby-marc`. Please use MARC::JREXMLReader or MARC::NokogiriReader instead.

## Miscellany

Source code at: https://github.com/ruby-marc/ruby-marc/

Find generated API docs at: http://rubydoc.info/gems/marc/frames

Run automated tests in source with `rake test`.

Developers, release new version of gem to rubygems with `rake release`
(bundler-supplied task). Note that one nice thing this will do is
automatically tag the version in git, very important for later figuring out
what's going on.

## Installation

    gem install marc

Or if you're using bundler, add to your Gemfile

    gem 'marc'

## Authors

Kevin Clarke <ksclarke@gmail.com>
Bill Dueber <bill@dueber.com>
William Groppe <will.groppe@gmail.com>
Ross Singer <rossfsinger@gmail.com>
Ed Summers <ehs@pobox.com>
