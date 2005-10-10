require 'test/unit'
require 'marc'

class ReaderTest < Test::Unit::TestCase

    def test_batch
        reader = MARC::Reader.new('test/batch.dat')
        count = 0
        reader.each { count += 1 }
        assert_equal(count, 10)
    end

    def test_search
        reader = MARC::Reader.new('test/batch.dat')
        records = reader.find_all { |r| r =~ /Perl/ }
        assert_equal(records.length,10)

        reader = MARC::Reader.new('test/batch.dat')
        records = reader.find_all { |r| r['245'] =~ /Perl/ }
        assert_equal(records.length,10)

        reader = MARC::Reader.new('test/batch.dat')
        records = reader.find_all { |r| r['245']['a'] =~ /Perl/ }
        assert_equal(records.length,10)

        reader = MARC::Reader.new('test/batch.dat')
        records = reader.find_all { |r| r =~ /Foo/ }
        assert_equal(records.length,0)
    end

end
