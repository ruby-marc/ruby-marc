require "test/unit"
require "marc"

class BadXMLHandlingTestCase < Test::Unit::TestCase
  def test_nokogiri_bad_xml
    begin
      require "nokogiri"
    rescue LoadError
      omit("nokogiri not installed, cannot test")
    end
    omit("nokogiri (<1.10.2) under jruby doesn't support error handling: sparklemotion/nokogiri#1847") if RUBY_PLATFORM == "java" && Gem::Version.new(Nokogiri::VERSION) < Gem::Version.new("1.10.2")
    count = 0
    reader = MARC::XMLReader.new("test/three-records-second-bad.xml", parser: :nokogiri)
    assert_raise MARC::XMLParseError do
      reader.each do |rec|
        count += 1 if rec["260"]
      end
    end
    assert_equal(1, count, "should only be able to parse one record")
  end
end
