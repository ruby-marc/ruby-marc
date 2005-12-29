require 'test/unit'
require 'marc'

class WriterTest < Test::Unit::TestCase

  def test_writer()
    # get a record
    reader = MARC::Reader.new('test/one.dat')
    record = reader.entries[0]

    str_writer = StringWriter.new()
    xml_writer = MARC::XMLWriter.new(str_writer)
    xml_writer.write(record)
    assert_match /<\?xml version='1.0'\?>/, str_writer.buffer
  end
end

# little class that enables wriing to a string
# like it's a file

class StringWriter
  attr_reader :buffer

  def initialize
    @buffer = ''
  end

  def write(str)
    @buffer += str
  end

  def to_s
    return @buffer
  end
end


