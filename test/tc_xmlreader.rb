require 'test/unit'
require 'marc'

class XMLReaderTest < Test::Unit::TestCase
  def test_reader
    reader = MARC::XMLReader.new('test/batch.xml')
    for record in reader
      # TODO: more complete verification that it's really working!
      assert_instance_of(MARC::Record, record)
    end
  end
end

