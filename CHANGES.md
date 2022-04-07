# MARC Changelog

## Version 1.x

### v1.2.0 

Major changes to XML handling. Everything is API backwards-compatible, 
although the underlying implementation may have changed. 

#### Bug fix: MARC-XML output no longer changes the record being written

The `XMLWriter` does basic data sanitizing (e.g., making sure the
leader ends in 4500). Previous code not only wrote out the
fixed record, but actually changed the underlying record as a side effect.
The act of outputting a record shouldn't alter it, and this has been
fixed. 

#### Remove all XML parsers except for Nokogiri

Note: the public API hasn't changed at all, it's just that no matter
what you do, you get a Nokogiri reader.

`ruby-marc` existed before bundler and before nokogiri on JRuby was 
a good-enough thing. Now that bundler will always install nokogiri,
there's no reason to not use it. It's more performant than the other
options and is solid across platforms. 

In this version, no matter what options or parser selection calls are
made when creating/configuring an `XMLReader`, the resulting reader
always uses the nokogiri pull parser.

This makes the `MagicParser` class always return a nokogiri parser, 
ignores any `parser:` argument to `XMLReader.new`,
and makes the following `XMLReader` class methods no-ops:

* `parser=`
* `best_available`
* `nokogiri!`
* `jrexml!`
* `rexml`
* `jstax!`

#### Faster MARC-XML record generation

For historic reasons, `MARC::XMLWriter.encode(record)` (and its
wrapper `MARC::Record.to_xml`) returns a REXML document representing
the MARC-XML for that record. The most common use it to just
get the XML string with `record.to_xml.to_s`. 

The REXML writer is very slow, on my hardware doing 200-300 writes
per second. If you're writing out XML, that represents the upper
limit on how fast you'll be able to process records. 

We now provide two other ways to get a MARC-XML string:

* `record.to_xml_string` uses `MARC::XMLWriter.encode_to_xml_string`,
  which uses a nokogiri-based document creator. It's 2-4 times faster
  than the current REXML encoder.
* `record.to_xml_string_unsfae` uses
  `MARC::UnsafeXMLWriter.encode`, a copy of 
  `MARC::FastXMLWriter` which has been floating around for a few years now.
  It uses simple string concatenation to create the MARC-XML, which
  doesn't have the syntax/semantics checks you get from something like
  nokogiri but is faster

Note that while the unsafe version doesn't come with guarantees of 
correctness you get from the other versions, it's been in production
use for years without any problems.

In general, the unsafe version is 4-5 times faster than the nokogiri version
and 13-20 times faster than the current REXML-based version.


```text
Simple benchmark testing MARC-XML string production

ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-darwin19]

    rec.to_xml_string_unsafe:     4408.2 i/s
           rec.to_xml_string:     990.0 i/s - 4.45x  (± 0.00) slower
             rec.to_xml.to_s:      294.0 i/s - 15.00x  (± 0.00) slower

ruby 3.1.0p0 (2021-12-25 revision fb4df44d16) [x86_64-darwin21]

    rec.to_xml_string_unsafe:     4537.0 i/s
           rec.to_xml_string:     1028.6 i/s - 4.41x  (± 0.00) slower
             rec.to_xml.to_s:      226.6 i/s - 20.03x  (± 0.00) slower

jruby 9.3.2.0 (2.6.8) 2021-12-01 0b8223f905 OpenJDK 64-Bit Server VM 11.0.2+9 on 11.0.2+9 +jit [darwin-x86_64]

    rec.to_xml_string_unsafe:     4930.9 i/s
           rec.to_xml_string:      883.0 i/s - 5.58x  (± 0.00) slower
             rec.to_xml.to_s:      384.5 i/s - 12.83x  (± 0.00) slower

```

#### Faster MARC-XML output to file

When writing to a file/handle, the code internally now uses the 
nokogiri-based code, so writing XML to a file should show the same
4-5x speedup.


#### 7-10% Faster Nokogiri parsing

Additionally, the pull parser itself was modified slightly. When checking to
see what kind of XML tag was just read, it now checks in the order
of most-common to least-common tags, starting with `subfield` and 
ending with `leader` and `record`. This allows the `case` statement to 
short-circuit, resulting in a surprisingly substantial 10% speed increase.

```text
ruby 2.7.1p83 (2020-03-31 revision a0c7c23c9c) [x86_64-darwin19]
  Type      	Runs	 Total	   Avg
  old order 	   4	 44.53	 11.13
  new order 	   4	 40.39	 10.10

  New version takes 91% as long


ruby 3.1.0p0 (2021-12-25 revision fb4df44d16) [x86_64-darwin21]
  Type      	Runs	 Total	   Avg
  old order 	   4	 43.40	 10.85
  new order 	   4	 39.07	  9.77

  New version takes 90% as long


jruby 9.3.2.0 (2.6.8) 2021-12-01 0b8223f905 OpenJDK 64-Bit Server VM 11.0.2+9 on 11.0.2+9 +jit [darwin-x86_64]
  Type      	Runs	 Total	   Avg
  old order 	   4	 34.75	  8.69
  new order 	   4	 32.47	  8.12
  
  New version takes 93% as long

```



### v1.1.2 (next)
- Fix JRubySTAXReader to use :: syntax for constant access as required by
  JRuby 9.3+.
- Document JAVA_OPTS workaround for JRubySTAXReader module encapsulation
  issue under Java 9+.
- Deprecate JRubySTAXReader.

### v1.1.1 June 2021
- Fix a regression when normalizing indicator values when serializing marcxml

### v1.1.0 June 2021
 - Add support for additional valid subfield codes in marcxml

### v1.0.2 July 2017
 - Now (correctly) throw an error if datafield string is the empty string
   (thanks to @bibliotechy)

### v1.0.1 February 2016
- Non-user-facing change in implementation of FieldMap strictly for performance

### v1.0.0 January 2015
- Mostly changes that deal with encoding, plus the plunge to a 1.0 release

## Pre-1.0

### v0.5.0 April 2012
- Extensive rewrite of MARC::Reader (ISO 2709 binary reader) to provide a
  fairly complete and consistent handing of char encoding issues in ruby 1.9.
  - This code is well covered by automated tests, but ends up complex, there
    may be bugs, please report them.
  - May not work properly under jruby with non-unicode source encodings.
  - Still can't handle Marc8 encoding.
  - May not have entirely backwards compatible behavior with regard to char
    encodings under ruby 1.9.x as previous 0.4.x versions. Test your code.
    In particular, previous versions may have automatically _transcoded_
    non-unicode encodings to UTF-8 for you. This version will not do
    so unless you ask it to with correct arguments.

### v0.4.4 Sat Mar 03 14:55:00 EDT 2012
- Fixed performance regression: strict reader will parse about 5x faster now
- Updated CHANGES file for first time in a long time :-)

### v0.3.0 Wed Sep 23 21:51:00 EDT 2009
- Nokogiri and jrexml parser integration added as well as Ruby 1.9 support

### v0.2.2 Tue Dec 30 09:50:33 EST 2008
- DataField tags that are all numeric are now padded with leading zeros

### v0.2.1 Mon Aug 18 14:14:16 EDT 2008
- can now process records that have fields tags that are non-numeric (thanks
  Ross Singer)

### v0.2.0 Wed Jun 11 12:42:20 EDT 2008
- added newline to output generated by REXML::Formatters::Default to make
  it a bit more friendly. REXML::Formatters::Pretty and Transitive just
  don't do what I want (whitespace in weird places).

### v0.1.9 Thu Jun  5 12:00:01 EDT 2008
- small docfix change in XMLReader
- use REXML::Formatters::Default instead of deprecated REXML::Element.write

### v0.1.8 Tue Nov 13 22:51:03 EST 2007
- added examples directory
- fixed problem with leading whitespace and the leader in xml reader
  (thanks Morgan Cundiff)

### v0.1.7 Mon Nov 12 09:33:57 EST 2007
- updated Record.to_marc documentation to be a bit more precise
- removed doc references to MARC::Field which is no longer around
- changed from Artistic to MIT License

### v0.1.6 Fri May  4 12:37:33 EDT 2007
- fixed bad record length test
- removed MARC::XMLWriter convert_to_utf8 which wasn't really working and
  shouldn't be there if it isn't good
- added unescaping of entities to MARC::XMLReader

### v0.1.5 Tue May  1 16:50:02 EDT 2007
- docfix in MARC::DataField (thanks Jason Ronallo)
- multiple docfixes (thanks Jonathan Rochkind)

### v0.1.4 Tue Jan  2 15:45:53 EST 2007
- fixed bug in MARC::XMLWriter that was outputting all control field tags as 00z
  (thanks Ross Singer)
- added :include_namespace option to MARC::XMLWriter::encode to include the
  marcxml namespace, which allows MARC::Record::to_xml to emit the namespace
  for a single record.

### v0.1.3  Tue Jan  2 12:56:36 EST 2007
- added ability to map a MARC record to the Dublin Core fields.  Calling
  to_dublin_core on a MARC::Record returns a hash that has Dublin Core fields
  as the hash keys.

### v0.1.2  Thu Dec 21 18:46:01 EST 2007
- fixed MARC::Record::to_xml so that it actually is tested and works (thanks
  Ross Singer)

### v0.1.1
- added ability to pass File like objects to the constructor for
  MARC::XMLReader like MARC::Reader (thanks Jake Glenn)

### v0.1.0  Wed Dec  6 15:40:40 EST 2006
- fixed pretty xml when stylesheet is used
- added value() to MARC::DataField
- added Rakefile for testing/building

### v0.0.9  Tue Mar 28 10:02:16 CST 2006
- changed XMLWriter.write to output pretty-printed XML
- normalized Text in XML output
- added XMLWriter checks and replacements for bad subfield codes and indicator
  values
- added XMLWriter check and replacement for invalid control codes in xml data
  values
- added XMLWriter checks for values in the leader that are invalid MARCXML
- added bin/marc2xml
- collapsed tc_xmlreader.rb tc_xmlwriter.rb into tc_xml.rb for full write/read
  test.
- added :stylesheet argument to XLMWriter.new

### v0.0.8  Mon Jan 16 22:31:00 EST 2006
- removed control tests out of tc_field.rb into tc_control.rb
- fixed some formatting
- changed control/field to controlfield/datafield
- added == check for controlfield
- removed namespace declarations on record elements in favor of default
  namespace on collection element
- added spaces around subfield code and delimeter in to_s
- fixed up relevant tests that were expecting old formatting
- fixed xmlreader strip_ns which was rerturning Nil when no namespace
  was found on an element (exposed by namespace changes).

### v0.0.7  Mon Jan  2 21:39:28 CST 2006
- MARC::XMLWriter added
- removed encode/decode methods in MARC::MARC21 into MARC::Writer and
  MARC::Reader respectively. This required pushing MARC21 specific constants
  out into MARC::Constants which is required as necessary.
- moved encode from MARC::MARXML into MARC::XMLWriter and added constants
  to MARC::Constants
- added MARC::XMLReader for reading MARX as XML
- added xml reading tests
- fixed indentation to be two spaces

### v0.0.6  Tue Oct 18 09:33:12 CDT 2005
- MARC::MARC21::decode throws an exception when a directory can't be found.
  Exception is caught and ignored in MARC::ForgivingReader

### v0.0.5  Tue Oct 18 01:50:40 CDT 2005
- when unspecified field indicators are forced to blanks
- checking for when a field appears to not have indicators and subfields in
  which case the field is skipped entirely

### v0.0.4  Tue Oct 18 00:39:50 CDT 2005
- fixed off by one error when reading in leader, previous versions were
  reading an extra character

### v0.0.3  Mon Oct 17 22:51:23 CDT 2005
- added ForgivingReader class and support for reading records without using
  possibly faulty offsets when the user needs them.

### v0.0.2  Mon Oct 17 17:42:57 CDT 2005
- updated version string to see if it'll fix some gem oddness

### v0.0.1  Mon Oct 10 10:29:20 CDT 2005
- initial release
