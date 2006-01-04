require 'test/unit'
require 'marc'

class TestField < Test::Unit::TestCase

    def test_control
        control = MARC::Control.new('005', 'foobarbaz')
        assert_equal(control.to_s, '005 foobarbaz')
    end

    def test_field_as_control
        assert_raise(MARC::Exception) do
            # can't have a field with a tag < 010
            field = MARC::Field.new('007') 
        end
    end

    def test_control_as_field
        assert_raise(MARC::Exception) do
            # can't have a control with a tag > 009
            f = MARC::Control.new('245')
        end
    end
end

