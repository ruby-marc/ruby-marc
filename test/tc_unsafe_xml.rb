require "test/unit"
require "marc"
require "stringio"

class UnsafeXMLTest < Test::Unit::TestCase
  def basic_rec
    rec = MARC::Record.new
    rec.leader = "00925njm  22002777a 4500"
    rec.append MARC::ControlField.new("007", "sdubumennmplu")
    rec.append MARC::DataField.new("245", "0", "4",
      ["a", "The Great Ray Charles"], ["h", "[sound recording]."])
    rec.append MARC::DataField.new("998", " ", " ",
      ["^", "Valid local subfield"])
    rec
  end

  def text_xml_entities
    r1 = MARC::Record.new
    r1 << MARC::DataField.new("245", "0", "0", ["a", "foo & bar & baz"])
    xml = MARC::UnsafeXMLWriter.encode(r1)
    assert_match(/foo &amp; bar &amp; baz/, xml)
    reader = MARC::XMLReader.new(StringIO.new(xml), parser: parser)
    r2 = reader.entries[0]
    assert_equal "foo & bar & baz", r2["245"]["a"]
  end

  def test_read_write
    record1 = MARC::Record.new
    record1.leader = "00925njm  22002777a 4500"
    record1.append MARC::ControlField.new("007", "sdubumennmplu")
    record1.append MARC::DataField.new("245", "0", "4",
      ["a", "The Great Ray Charles"], ["h", "[sound recording]."])
    record1.append MARC::DataField.new("998", " ", " ",
      ["^", "Valid local subfield"])

    writer = MARC::UnsafeXMLWriter.new("test/test.xml", stylesheet: "style.xsl")
    writer.write(record1)
    writer.close

    xml = File.read("test/test.xml")
    assert_match(/<controlfield tag=["']007["']>sdubumennmplu<\/controlfield>/, xml)
    assert_match(/<\?xml-stylesheet type=["']text\/xsl" href="style.xsl["']\?>/, xml)

    reader = MARC::XMLReader.new("test/test.xml")
    record2 = reader.first
    assert_equal(record1, record2)
  ensure
    File.unlink("test/test.xml")
  end

  def test_truncated_leader_roundtripping
    record1 = MARC::Record.new
    record1.leader = "00925njm  22002777a"

    writer = MARC::UnsafeXMLWriter.new("test/test.xml", stylesheet: "style.xsl")
    writer.write(record1)
    writer.close

    reader = MARC::XMLReader.new("test/test.xml")
    record2 = reader.first

    assert_equal("00925njm  22002777a 4500", record2.leader)
  ensure
    File.unlink("test/test.xml")
  end

  def test_single_record_document
    xml = MARC::UnsafeXMLWriter.single_record_document(basic_rec)
    rec = MARC::XMLReader.new(StringIO.new(xml)).first
    assert_equal(basic_rec, rec)
  end

  def test_encode_same_as_rexml
    rex_xml = MARC::XMLWriter.encode(basic_rec).to_s
    unsafe_xml = MARC::UnsafeXMLWriter.encode(basic_rec)
    rex = MARC::XMLReader.new(StringIO.new(rex_xml)).first
    unsafe = MARC::XMLReader.new(StringIO.new(unsafe_xml)).first
    assert_equal(rex, unsafe)
  end

  def test_to_xml_string
    rex_xml = basic_rec.to_xml_string
    unsafe_xml = basic_rec.to_xml_string(fast_but_unsafe: true, include_namespace: false)
    rex = MARC::XMLReader.new(StringIO.new(rex_xml)).first
    unsafe = MARC::XMLReader.new(StringIO.new(unsafe_xml)).first
    assert_equal(rex, unsafe)
  end

  def test_to_xml_string_with_namespaces
    unsafe_xml = basic_rec.to_xml_string(fast_but_unsafe: true, include_namespace: true)
    rex = MARC::XMLReader.new(StringIO.new(unsafe_xml)).first
    unsafe = MARC::XMLReader.new(StringIO.new(unsafe_xml)).first
    assert_equal(rex, unsafe)
  end
end
