# encoding: UTF-8

require_relative './test_helper'
require 'marc'

class TestField < Minitest::Test

    def test_tag
        f1 = MARC::DataField.new('100')
        assert_equal('100', f1.tag)
        f2 = MARC::DataField.new(tag='100')
        assert_equal('100', f2.tag)
        assert_equal(f1, f2)
        f3 = MARC::DataField.new('245')
        refute_equal(f1, f3)
    end

    def test_alphabetic_tag
        alph = MARC::DataField.new('ALF')
        assert_equal 'ALF', alph.tag

        alphnum = MARC::DataField.new('0D9')
        assert_equal '0D9', alphnum.tag
    end

    def test_indicators
        f1 = MARC::DataField.new('100', '0', '1')
        assert_equal('0', f1.indicator1)
        assert_equal('1', f1.indicator2)
        f2 = MARC::DataField.new(tag='100',i1='0',i2='1')
        assert_equal('0', f2.indicator1)
        assert_equal('1', f2.indicator2)
        assert_equal(f1, f2)
        f3 = MARC::DataField.new(tag='100', i1='1', i2='1')
        refute_equal(f1, f3)
    end

    def test_subfields
        f1 = MARC::DataField.new('100', '0', '1',
            MARC::Subfield.new('a', 'Foo'),
            MARC::Subfield.new('b', 'Bar') )
        assert_equal("100 01 $a Foo $b Bar ", f1.to_s)
        assert_equal("FooBar", f1.value)
        f2 = MARC::DataField.new('100', '0', '1',
            MARC::Subfield.new('a', 'Foo'),
            MARC::Subfield.new('b', 'Bar') )
        assert_equal(f1,f2)
        f3 = MARC::DataField.new('100', '0', '1',
            MARC::Subfield.new('a', 'Foo'),
            MARC::Subfield.new('b', 'Bez') )
        refute_equal(f1,f3)
    end

    def test_subfield_shorthand
        f  = MARC::DataField.new('100', '0', '1', ['a', 'Foo'], ['b', 'Bar'])
        assert_equal('100 01 $a Foo $b Bar ', f.to_s)
    end


    def test_iterator
        field = MARC::DataField.new('100', '0', '1', ['a', 'Foo'],['b', 'Bar'],
            ['a', 'Bez'])
        count = 0
        field.each {|x| count += 1}
        assert_equal(count,3)
    end

    def test_lookup_shorthand
        f  = MARC::DataField.new('100', '0', '1', ['a', 'Foo'], ['b', 'Bar'])
        assert_equal(f['b'], 'Bar')
    end

end
