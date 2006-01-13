require 'test/unit'
require 'marc'

class XMLReaderTest < Test::Unit::TestCase

  def otest_batch
    reader = MARC::XMLReader.new('test/batch.xml')
    count = 0
    for record in reader
      count += 1
      assert_instance_of(MARC::Record, record)
    end
    assert_equal(count, 2)
  end

  def test_read_write
    record1 = MARC::Record.new
    record1.leader =  '00925njm  22002777a 4500'
    record1.append MARC::ControlField.new('007', 'sdubumennmplu')
    record1.append MARC::DataField.new('245', '0', '4', 
      ['a', 'The Great Ray Charles'], ['h', '[sound recording].'])

    writer = MARC::XMLWriter.new('test/foo.xml')
    writer.write(record1)
    writer.close

    reader = MARC::XMLReader.new('test/foo.xml')
    record2 = reader.entries[0]
    assert_equal(record1, record2)

    #File.unlink('test/foo.xml')
  end
end

