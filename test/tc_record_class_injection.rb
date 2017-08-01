require 'test/unit'
require 'marc/record'
require 'marc/reader'
require 'marc/xmlreader'

class MyRecord < MARC::Record
  def isbn
    self['020'] and self['020']['a']
  end

  def lccn
    self['010'] and self['010']['a']
  end
end

class RecordClassInjectionTest < MiniTest::Unit::TestCase
  def test_ok
    assert_equal(1,1, 'Yup. working')
  end

  def test_injection
    reader = MARC::Reader.new('test/one.dat')
    r = reader.first
    assert_raises(NoMethodError) do
      r.isbn
    end

    reader = MARC::Reader.new('test/one.dat', :record_class => MyRecord)
    r = reader.first
    assert_equal("0471383147 (paper/cd-rom : alk. paper)", r.isbn)
  end

  def test_xml_injection
    reader = MARC::XMLReader.new('test/one.xml')
    r = reader.first
    assert_raises(NoMethodError) do
      r.isbn
    end

    reader = MARC::XMLReader.new('test/one.xml', :record_class => MyRecord)
    r = reader.first
    assert_equal("afc99990058366", r.lccn)

  end

end
