require 'helper'
require 'marc'

class DublinCoreTest < MiniTest::Unit::TestCase

    def test_mapping
        reader = MARC::Reader.new('test/data/batch.dat')
        reader.each do |record|
          dc = record.to_dublin_core
          assert dc['title'] == record['245']['a']
        end
    end

end