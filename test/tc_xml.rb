require 'test/unit'
require 'marc'
require 'stringio'

class XMLTest < Test::Unit::TestCase
  def setup
    @parsers = [:rexml]
    begin
      require 'nokogiri'
      @parsers << :nokogiri
    rescue LoadError
    end
    unless defined? JRUBY_VERSION
      begin
        require 'xml'
        @parsers << :libxml
      rescue LoadError
      end
    end
    if defined? JRUBY_VERSION
      begin
        require 'jrexml'
        @parsers << :jrexml
      rescue LoadError
      end
      begin
        java.lang.Class.forName("javax.xml.stream.XMLInputFactory")
        @parsers << :jstax
      rescue java.lang.ClassNotFoundException
      end
    end
  end

  def test_xml_entities
    @parsers.each do |parser|
      puts "\nRunning test_xml_entities with: #{parser}.\n"
      xml_entities_test(parser)
    end
  end

  def xml_entities_test(parser)
    r1 = MARC::Record.new
    r1 << MARC::DataField.new('245', '0', '0', ['a', 'foo & bar & baz'])
    xml = r1.to_xml.to_s
    assert_match(/foo &amp; bar &amp; baz/, xml)

    reader = MARC::XMLReader.new(StringIO.new(xml), :parser => parser)
    r2     = reader.entries[0]
    assert_equal 'foo & bar & baz', r2['245']['a']
  end

  def test_batch
    @parsers.each do |parser|
      puts "\nRunning test_batch with: #{parser}.\n"
      batch_test(parser)
    end
  end

  def batch_test(parser)
    reader = MARC::XMLReader.new('test/batch.xml', :parser => parser)
    count  = 0
    for record in reader
      count += 1
      assert_instance_of(MARC::Record, record)
    end
    assert_equal(count, 2)
  end

  def test_read_string
    @parsers.each do |parser|
      puts "\nRunning test_read_string with: #{parser}.\n"
      read_string_test(parser)
    end
  end

  def read_string_test(parser)
    xml    = File.new('test/batch.xml').read
    reader = MARC::XMLReader.new(StringIO.new(xml), :parser => parser)
    assert_equal 2, reader.entries.length
  end

  def test_non_numeric_fields
    @parsers.each do |parser|
      puts "\nRunning test_non_numeric_fields with: #{parser}.\n"
      non_numeric_fields_test(parser)
    end
  end

  def non_numeric_fields_test(parser)
    reader = MARC::XMLReader.new('test/non-numeric.xml', :parser => parser)
    count  = 0
    record = nil
    reader.each do |rec|
      count  += 1
      record = rec
    end
    assert_equal(1, count)
    assert_equal('9780061317842', record['ISB']['a'])
    assert_equal('1', record['LOC']['9'])
  end

  def test_read_no_leading_zero_write_leading_zero
    @parsers.each do |parser|
      puts "\nRunning test_read_no_leading_zero_write_leading_zero with: #{parser}.\n"
      read_no_leading_zero_write_leading_zero_test(parser)
    end
  end

  def read_no_leading_zero_write_leading_zero_test(parser)
    reader = MARC::XMLReader.new('test/no-leading-zero.xml', :parser => parser)
    record = reader.to_a[0]
    assert_equal("042 zz $a dc ", record['042'].to_s)
  end

  def test_leader_from_xml
    @parsers.each do |parser|
      puts "\nRunning test_leader_from_xml with: #{parser}.\n"
      leader_from_xml_test(parser)
    end
  end

  def leader_from_xml_test(parser)
    reader = MARC::XMLReader.new('test/one.xml', :parser => parser)
    record = reader.entries[0]
    assert_equal '     njm a22     uu 4500', record.leader
    # serializing as MARC should populate the record length and directory offset
    record = MARC::Record.new_from_marc(record.to_marc)
    assert_equal '00734njm a2200217uu 4500', record.leader
  end

  def test_read_write
    @parsers.each do |parser|
      puts "\nRunning test_read_write with: #{parser}.\n"
      read_write_test(parser)
    end
  end

  def read_write_test(parser)
    record1        = MARC::Record.new
    record1.leader = '00925njm  22002777a 4500'
    record1.append MARC::ControlField.new('007', 'sdubumennmplu')
    record1.append MARC::DataField.new('245', '0', '4',
                                       ['a', 'The Great Ray Charles'], ['h', '[sound recording].'])
    record1.append MARC::DataField.new('998', ' ', ' ',
                                       ['^', 'Valid local subfield'])

    # MARC::XMLWriter mutates records
    dup_record = MARC::Record.new_from_hash(record1.to_hash)

    writer = MARC::XMLWriter.new('test/test.xml', :stylesheet => 'style.xsl')
    writer.write(dup_record)
    writer.close

    xml = File.read('test/test.xml')
    assert_match(/<controlfield tag='007'>sdubumennmplu<\/controlfield>/, xml)
    assert_match(/<\?xml-stylesheet type="text\/xsl" href="style.xsl"\?>/, xml)

    reader  = MARC::XMLReader.new('test/test.xml', :parser => parser)
    record2 = reader.entries[0]
    assert_equal(record1, record2)

    File.unlink('test/test.xml')
  end

  def test_xml_enumerator
    @parsers.each do |parser|
      puts "\nRunning test_xml_enumerator with: #{parser}.\n"
      xml_enumerator_test(parser)
    end
  end

  def xml_enumerator_test(parser)
    # confusingly, test/batch.xml only has two records, not 10 like batch.dat
    reader = MARC::XMLReader.new('test/batch.xml', :parser => parser)
    iter   = reader.each
    r      = iter.next
    assert_instance_of(MARC::Record, r)
    iter.next # total of two records
    assert_raises(StopIteration) { iter.next }
  end

end

