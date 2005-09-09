require 'test/unit'
require 'marc/field'
require 'marc/subfield'

class TestField < Test::Unit::TestCase

    def xtest_tag
        f1 = Field.new('100')
        assert_equal('100', f1.tag)
        f2 = Field.new(tag='100')
        assert_equal('100', f2.tag)
        assert_equal(f1, f2)
        f3 = Field.new('245')
        assert_not_equal(f1, f3)
    end

    def xtest_indicators
        f1 = Field.new('100', '0', '1')
        assert_equal('0', f1.indicator1)
        assert_equal('1', f1.indicator2)
        f2 = Field.new(tag='100',i1='0',i2='1')
        assert_equal('0', f2.indicator1)
        assert_equal('1', f2.indicator2)
        assert_equal(f1,f2)
        f3 = Field.new(tag='100',i1='1',i2='1')
        assert_not_equal(f1, f3)
    end

    def test_subfields
        f1 = Field.new('100', '0', '1', Subfield.new('a', 'Foo'))
        assert_equal("100 01 $a Foo", f1.to_a)
        f2 = Field.new('100', '0', '1', 'a', 'Foo')
        assert_equal("100 01 $a Foo", f2.to_a)
    end

    def test_enumerable
        #f = Field.new('100','0','1', 'a','Foo','b','Bar','a','Bez')
    end

end
