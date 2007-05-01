require 'test/unit'
require 'marc'

class ReaderTest < Test::Unit::TestCase

  def test_batch
    reader = MARC::Reader.new('test/batch.dat')
    count = 0
    reader.each { count += 1 }
    assert_equal(count, 10)
  end

  def test_loose
    reader = MARC::ForgivingReader.new('test/batch.dat')
    count = 0
    reader.each { count += 1 }
    assert_equal(10, count)
  end

  def test_bad_marc
    reader = MARC::Reader.new('test/tc_reader.rb')
    record = reader.entries[0]
  end

  def test_search
    reader = MARC::Reader.new('test/batch.dat')
    records = reader.find_all { |r| r =~ /Perl/ }
    assert_equal(10, records.length)

    reader = MARC::Reader.new('test/batch.dat')
    records = reader.find_all { |r| r['245'] =~ /Perl/ }
    assert_equal(10, records.length)

    reader = MARC::Reader.new('test/batch.dat')
    records = reader.find_all { |r| r['245']['a'] =~ /Perl/ }
    assert_equal(10, records.length)

    reader = MARC::Reader.new('test/batch.dat')
    records = reader.find_all { |r| r =~ /Foo/ }
    assert_equal(0, records.length)
  end

end
