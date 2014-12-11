# encoding: UTF-8

require_relative './test_helper'
require 'marc'

class DublinCoreTest < Minitest::Test

    def test_mapping
        reader = MARC::Reader.new('test/batch.dat')
        reader.each do |record|
          dc = record.to_dublin_core
          assert dc['title'] == record['245']['a']
        end
    end

end
