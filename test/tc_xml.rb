require 'test/unit'
require 'marc'
require 'stringio'

class XMLTest < Test::Unit::TestCase

  def test_batch
    reader = MARC::XMLReader.new('test/batch.xml')
    count = 0
    for record in reader
      count += 1
      assert_instance_of(MARC::Record, record)
    end
    assert_equal(count, 2)
  end

  def test_read_string
    xml = File.new('test/batch.xml').read
    reader = MARC::XMLReader.new(StringIO.new(xml))
    assert_equal reader.entries.length, 2 
  end

  def test_read_write
    record1 = MARC::Record.new
    record1.leader =  '00925njm  22002777a 4500'
    record1.append MARC::ControlField.new('007', 'sdubumennmplu')
    record1.append MARC::DataField.new('245', '0', '4', 
      ['a', 'The Great Ray Charles'], ['h', '[sound recording].'])

    writer = MARC::XMLWriter.new('test/test.xml', :stylesheet => 'style.xsl')
    writer.write(record1)
    writer.close

    xml = File.read('test/test.xml')
    assert_match /<\?xml-stylesheet type="text\/xsl" href="style.xsl"\?>/, xml

    reader = MARC::XMLReader.new('test/test.xml')
    record2 = reader.entries[0]
    assert_equal(record1, record2)

    File.unlink('test/test.xml')
  end

end

