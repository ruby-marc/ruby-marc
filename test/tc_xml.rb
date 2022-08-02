require "test/unit"
require "marc"
require "stringio"
require "warning"

class XMLTest < Test::Unit::TestCase
  Warning.ignore(/is deprecated and will be removed in a future version of ruby-marc/)
  Warning.ignore(/setting Encoding.default_internal/)
  def setup
    @parsers = [:rexml]
    begin
      require "nokogiri"
      @parsers << :nokogiri
    rescue LoadError
    end
    unless defined? JRUBY_VERSION
      begin
        require "xml"
        @parsers << :libxml
      rescue LoadError
      end
    end
    if defined? JRUBY_VERSION
      begin
        java.lang.Class.forName("javax.xml.stream.XMLInputFactory")
        @parsers << :jstax
      rescue java.lang.ClassNotFoundException
      end
    end
  end

  def test_xml_entities
    @parsers.each do |parser|
      xml_entities_test(parser)
    end
  end

  def xml_entities_test(parser)
    r1 = MARC::Record.new
    r1 << MARC::DataField.new("245", "0", "0", ["a", "foo & bar & baz"])
    xml = r1.to_xml.to_s
    assert_match(/foo &amp; bar &amp; baz/, xml, "Failed with parser '#{parser}'")

    reader = MARC::XMLReader.new(StringIO.new(xml), parser: parser)
    r2 = reader.entries[0]
    assert_equal("foo & bar & baz", r2["245"]["a"], "Failed with parser '#{parser}'")
  end

  def test_batch
    @parsers.each do |parser|
      batch_test(parser)
    end
  end

  def batch_test(parser)
    reader = MARC::XMLReader.new("test/batch.xml", parser: parser)
    count = 0
    reader.each do |record|
      count += 1
      assert_instance_of(MARC::Record, record, "Failed with parser '#{parser}'")
    end
    assert_equal(count, 2, "Failed with parser '#{parser}'")
  end

  def test_read_string
    @parsers.each do |parser|
      read_string_test(parser)
    end
  end

  def read_string_test(parser)
    xml = File.new("test/batch.xml").read
    reader = MARC::XMLReader.new(StringIO.new(xml), parser: parser)
    assert_equal 2, reader.entries.length, "Failed with parser '#{parser}'"
  end

  def test_non_numeric_fields
    @parsers.each do |parser|
      non_numeric_fields_test(parser)
    end
  end

  def non_numeric_fields_test(parser)
    reader = MARC::XMLReader.new("test/non-numeric.xml", parser: parser)
    count = 0
    record = nil
    reader.each do |rec|
      count += 1
      record = rec
    end
    assert_equal(1, count, "Failed with parser '#{parser}'")
    assert_equal("9780061317842", record["ISB"]["a"], "Failed with parser '#{parser}'")
    assert_equal("1", record["LOC"]["9"], "Failed with parser '#{parser}'")
  end

  def test_read_no_leading_zero_write_leading_zero
    @parsers.each do |parser|
      read_no_leading_zero_write_leading_zero_test(parser)
    end
  end

  def read_no_leading_zero_write_leading_zero_test(parser)
    reader = MARC::XMLReader.new("test/no-leading-zero.xml", parser: parser)
    record = reader.to_a[0]
    assert_equal("042 zz $a dc ", record["042"].to_s, "Failed with parser '#{parser}'")
  end

  def test_leader_from_xml
    @parsers.each do |parser|
      leader_from_xml_test(parser)
    end
  end

  def leader_from_xml_test(parser)
    reader = MARC::XMLReader.new("test/one.xml", parser: parser)
    record = reader.entries[0]
    assert_equal "     njm a22     uu 4500", record.leader, "Failed with parser '#{parser}'"

    # serializing as MARC should populate the record length and directory offset
    record = MARC::Record.new_from_marc(record.to_marc)
    assert_equal "00734njm a2200217uu 4500", record.leader, "Failed with parser '#{parser}'"
  end

  def test_read_write
    @parsers.each do |parser|
      read_write_test(parser)
    end
  end

  def read_write_test(parser)
    record1 = MARC::Record.new
    record1.leader = "00925njm  22002777a 4500"
    record1.append MARC::ControlField.new("007", "sdubumennmplu")
    record1.append MARC::DataField.new("245", "0", "4",
      ["a", "The Great Ray Charles"], ["h", "[sound recording]."])
    record1.append MARC::DataField.new("998", " ", " ",
      ["^", "Valid local subfield"])

    writer = MARC::XMLWriter.new("test/test.xml", stylesheet: "style.xsl")
    writer.write(record1)
    writer.close

    xml = File.read("test/test.xml")
    assert_match(/<controlfield tag='007'>sdubumennmplu<\/controlfield>/, xml, "Failed with parser '#{parser}'")
    assert_match(/<\?xml-stylesheet type="text\/xsl" href="style.xsl"\?>/, xml, "Failed with parser '#{parser}'")

    reader = MARC::XMLReader.new("test/test.xml", parser: parser)
    record2 = reader.entries[0]
    assert_equal(record1, record2, "Failed with parser '#{parser}'")
  ensure
    File.unlink("test/test.xml")
  end

  def test_xml_enumerator
    @parsers.each do |parser|
      xml_enumerator_test(parser)
    end
  end

  def xml_enumerator_test(parser)
    # confusingly, test/batch.xml only has two records, not 10 like batch.dat
    reader = MARC::XMLReader.new("test/batch.xml", parser: parser)
    iter = reader.each
    r = iter.next
    assert_instance_of(MARC::Record, r, "Failed with parser '#{parser}'")
    iter.next # total of two records
    assert_raise(StopIteration, "Failed with parser '#{parser}'") { iter.next }
  end

  def test_truncated_leader_roundtripping
    record1 = MARC::Record.new
    record1.leader = "00925njm  22002777a"

    writer = MARC::XMLWriter.new("test/test.xml", stylesheet: "style.xsl")
    writer.write(record1)
    writer.close

    reader = MARC::XMLReader.new("test/test.xml")
    record2 = reader.entries[0]

    assert_equal("00925njm  22002777a 4500", record2.leader)
  ensure
    File.unlink("test/test.xml")
  end

  def test_xml_weird_leader
    @parsers.each do |parser|
      reader = MARC::XMLReader.new("test/messed_up_leader.xml", parser: parser)
      record = reader.first
      assert_equal(record.leader, "01301nam a22003618< 4500", "Failed with parser '#{parser}'")
    end
  end
end
