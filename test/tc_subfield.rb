# encoding: UTF-8

require_relative './test_helper'
require 'marc/subfield'

class SubfieldTest < Minitest::Test

    def test_ok
        s = MARC::Subfield.new('a', 'foo')
        assert_equal(s.code, 'a')
        assert_equal(s.value, 'foo')
    end

    def test_equals
        s1 =MARC::Subfield.new('a', 'foo')
        s2 =MARC::Subfield.new('a', 'foo')
        assert_equal(s1,s2)
    end

end
