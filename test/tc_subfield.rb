require 'test/unit'
require 'marc/subfield'

class SubfieldTest < Test::Unit::TestCase

    def test_ok
        s = Subfield.new('a','foo')
        assert_equal(s.code,'a')
        assert_equal(s.value,'foo')
    end

    def test_equals
        s1 =Subfield.new('a','foo')
        s2 =Subfield.new('a','foo')
        assert_equal(s1,s2)
    end

end
