require 'test/unit'
require 'marc'
require 'nokogiri'

class BadXMLHandlingTestCase < Test::Unit::TestCase

  def test_nokogiri_bad_xml
    count  = 0
    reader = MARC::XMLReader.new('test/three-records-second-bad.xml', :parser => :nokogiri)
    assert_raise MARC::XMLParseError do
      reader.each do |rec|
        count += 1 if rec['260']
      end
    end
    assert_equal(1, count, 'should only be able to parse one record')
  end
end
