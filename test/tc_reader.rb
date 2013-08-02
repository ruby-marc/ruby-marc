# -*- encoding: utf-8 -*-

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
  
  def test_loose_utf8
    # This isn't actually a corrupt file, but it is utf8, 
    # and I have some reason to believe forgiving reader isn't
    # working properly with UTF8 in ruby 1.9, so testing it. 
    reader = MARC::ForgivingReader.new('test/utf8.marc')
    count = 0
    reader.each { count += 1 }
    assert_equal(1, count)
  end
  
  def test_loose_unimarc
    # Unimarc might use a different record seperator? Let's make sure it works. 
    reader = MARC::Reader.new(File.open('test/cp866_unimarc.marc', 'r:cp866'))
    count = 0
    reader.each {|a| count += 1 }
    assert_equal(1, count)
  end

  def test_non_numeric_tags
    reader = MARC::Reader.new('test/non-numeric.dat')
    count = 0
    record = nil
    reader.each do | rec |
      count += 1
      record = rec
    end
    assert_equal(1, count)
    assert_equal('9780061317842', record['ISB']['a'])
    assert_equal('1', record['LOC']['9'])
  end

  def test_bad_marc
    reader = MARC::Reader.new('test/tc_reader.rb')
    assert_raises(MARC::Exception) {reader.entries[0]}
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
  
  def test_binary_enumerator
    reader = MARC::Reader.new('test/batch.dat')
    iter = reader.each
    r = iter.next
    assert_instance_of(MARC::Record, r)
    9.times {iter.next} # total of ten records
    assert_raises(StopIteration) { iter.next }  
  end

    

end
