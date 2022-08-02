# Changelog

All notable changes to this project will be documented in this file.

## [1.2] - 2022-08-02

### Added

* New XML writer `MARC::UnsafeXMLWriter` which is 15-20 times faster than the
  default (rexml-based) writer. It mirrors code from the old
  [`MARC::FastXMLWriter` gem](https://github.com/billdueber/marc-fastxmlwriter)
  in a way that integrates better with the existing writer framework. It can
  be used like any other writer,
  e.g., `writer = MARC::UnsafeXMLWriter. new(filename)`. Note that while it
  is "unsafe" in that it doesn't do checks for valid XML going out (it's speed
  comes from the fact that it's just concatenating strings together),
  the `FastXMLWriter` gem has been used "in the wild" for years and doesn't
  seem to cause anyone any problems.
* Added a new method, `MARC::Record.to_xml_string` which produces a
  valid `<record>...</record>` XML snippet. It takes an optional keyword
  argument to include namespace attributes on the
  `<record>` tag, and another to use the new unsafe generator as
  `record.to_xml_string(fast_but_unsafe: true)`.
* Added first-class support for `.jsonl` (aka "newline-delimited json")
  files using the marc-in-json format via `MARC::JSONLReader` and
  `MARC::JSONLWriter` which read and write marc-in-json. `ruby-marc` has
  supported `#to_hash` and `#from_hash` to deal with this format at the
  individual record level for a long time; this just provides the
  reader/writer scaffolding.
* Also added `MARC::Record.to_json_string` to get a marc-in-json string 
  representation (parallel to the new `#to_xml_string`)
* New option to xml readers to ignore any namespaces
  via `reader = MARC::XMLReader.new(filename, ignore_namespace: true)`. While
  the REXML MARC-XML reader can't handle
  (and thus has always ignored XML namespaces), the Nokogiri-based version
  will enforce namespaces if present. Useful only when you have
  poorly-generated files where the XML namespace attributes are wonky.
* All writers will now self-close if used with a block (e.g., 
  `MARC::Writer.new(filename) {|w| w.write(record)}`), parallel to the way 
  `File.open` works in regular ruby. 

### Changed
* 10-15% speed improvement when parsing MARC-XML with nokogiri (PR #97,
  billdueber)
* Added deprecation warnings when using the `libxml`, `jstax`, or `jrexml`
    xml parsers. When introduced, Nokogiri under JRuby was iffy. It's now
    stable on both MRI and JRuby and faster than any of the other 
    included options and should be preferred. (PR #98, billdueber)
* MARC fields are now validated in their own post-creation stage (PR #66,
  cbeer)
* Reduce the noise when running tests (billdueber)
* Reformatted this CHANGELOG.md file and added examples/structure to 
  README.md.


### Fixed
  * MARC-XML has requirements on the leader that are applied when writing out
    MARC-XML by `MARC::XMLWriter.encode`. Previous versions would actually
    mutate the record being written, resulting in a silent modification to
    a record just because you were writing it out. Changed to use a duplicate
    (PR #73, cbeer)
  * Guard against multiple character calls when parsing XML (PR #74, cbeer)
  * Minor Dublin Core code fixes (PRs #83 and #84, fjorba)
  * `JRubyStaxReader` now supports Java 9+ / JRuby 9.3+ (PR #87, dmolesUC)

## [1.1.1] - 2021-06-07

- Fix a regression when normalizing indicator values when serializing marcxml

## [1.1.0] - 2021-06-01
 - Add support for additional valid subfield codes in marcxml

## [1.0.2] - 2017-08-01
 - Now (correctly) throw an error if datafield string is the empty string
   (thanks to @bibliotechy)

## [1.0.1] - 2016-02-29
- Non-user-facing change in implementation of FieldMap strictly for performance

## [1.0.0]  - 2015-01-28
- Mostly changes that deal with encoding, plus the plunge to a 1.0 release

## [0.5.0] April 2012
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

## [0.4.4] Sat Mar 03 14:55:00 EDT 2012
- Fixed performance regression: strict reader will parse about 5x faster now
- Updated CHANGES file for first time in a long time :-)

## [0.3.0] Wed Sep 23 21:51:00 EDT 2009
- Nokogiri and jrexml parser integration added as well as Ruby 1.9 support

## [0.2.2] Tue Dec 30 09:50:33 EST 2008
- DataField tags that are all numeric are now padded with leading zeros

## [0.2.1] Mon Aug 18 14:14:16 EDT 2008
- can now process records that have fields tags that are non-numeric (thanks
  Ross Singer)

## [0.2.0] Wed Jun 11 12:42:20 EDT 2008
- added newline to output generated by REXML::Formatters::Default to make
  it a bit more friendly. REXML::Formatters::Pretty and Transitive just
  don't do what I want (whitespace in weird places).

## [0.1.9] -  Thu Jun  5 12:00:01 EDT 2008
- small docfix change in XMLReader
- use REXML::Formatters::Default instead of deprecated REXML::Element.write

## [0.1.8] -  Tue Nov 13 22:51:03 EST 2007
- added examples directory
- fixed problem with leading whitespace and the leader in xml reader
  (thanks Morgan Cundiff)

## [0.1.7] -  Mon Nov 12 09:33:57 EST 2007
- updated Record.to_marc documentation to be a bit more precise
- removed doc references to MARC::Field which is no longer around
- changed from Artistic to MIT License

## [0.1.6] -  Fri May  4 12:37:33 EDT 2007
- fixed bad record length test
- removed MARC::XMLWriter convert_to_utf8 which wasn't really working and
  shouldn't be there if it isn't good
- added unescaping of entities to MARC::XMLReader

## [0.1.5] -  Tue May  1 16:50:02 EDT 2007
- docfix in MARC::DataField (thanks Jason Ronallo)
- multiple docfixes (thanks Jonathan Rochkind)

## [0.1.4] -  Tue Jan  2 15:45:53 EST 2007
- fixed bug in MARC::XMLWriter that was outputting all control field tags as 00z
  (thanks Ross Singer)
- added :include_namespace option to MARC::XMLWriter::encode to include the
  marcxml namespace, which allows MARC::Record::to_xml to emit the namespace
  for a single record.

## [0.1.3] -   Tue Jan  2 12:56:36 EST 2007
- added ability to map a MARC record to the Dublin Core fields.  Calling
  to_dublin_core on a MARC::Record returns a hash that has Dublin Core fields
  as the hash keys.

## [0.1.2] -   Thu Dec 21 18:46:01 EST 2007
- fixed MARC::Record::to_xml so that it actually is tested and works (thanks
  Ross Singer)

## [0.1.1] - 
- added ability to pass File like objects to the constructor for
  MARC::XMLReader like MARC::Reader (thanks Jake Glenn)

## [0.1.0] -   Wed Dec  6 15:40:40 EST 2006
- fixed pretty xml when stylesheet is used
- added value() to MARC::DataField
- added Rakefile for testing/building

## [0.0.9] -   Tue Mar 28 10:02:16 CST 2006
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

## [0.0.8] -   Mon Jan 16 22:31:00 EST 2006
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

## [0.0.7] -   Mon Jan  2 21:39:28 CST 2006
- MARC::XMLWriter added
- removed encode/decode methods in MARC::MARC21 into MARC::Writer and
  MARC::Reader respectively. This required pushing MARC21 specific constants
  out into MARC::Constants which is required as necessary.
- moved encode from MARC::MARXML into MARC::XMLWriter and added constants
  to MARC::Constants
- added MARC::XMLReader for reading MARX as XML
- added xml reading tests
- fixed indentation to be two spaces

## [0.0.6] -   Tue Oct 18 09:33:12 CDT 2005
- MARC::MARC21::decode throws an exception when a directory can't be found.
  Exception is caught and ignored in MARC::ForgivingReader

## [0.0.5] -   Tue Oct 18 01:50:40 CDT 2005
- when unspecified field indicators are forced to blanks
- checking for when a field appears to not have indicators and subfields in
  which case the field is skipped entirely

## [0.0.4] -   Tue Oct 18 00:39:50 CDT 2005
- fixed off by one error when reading in leader, previous versions were
  reading an extra character

## [0.0.3] -   Mon Oct 17 22:51:23 CDT 2005
- added ForgivingReader class and support for reading records without using
  possibly faulty offsets when the user needs them.

## [0.0.2] -   Mon Oct 17 17:42:57 CDT 2005
- updated version string to see if it'll fix some gem oddness

## [0.0.1] -   Mon Oct 10 10:29:20 CDT 2005
- initial release
