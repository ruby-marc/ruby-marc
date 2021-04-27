require 'test/unit'
require 'marc'

class TestField < Test::Unit::TestCase

  def test_control
    control = MARC::ControlField.new('005', 'foobarbaz')
    assert_equal(control.to_s, '005 foobarbaz')
  end

  def test_field_as_control
    field = MARC::DataField.new('007')
    assert_equal(field.valid?, false)
  end

  def test_alpha_control_field
    # can't have a field with a tag < 010
    field = MARC::ControlField.new('DDD')
    assert_equal(field.valid?, false)
  end

  def test_extra_control_field
    MARC::ControlField.control_tags << 'FMT'
    field = MARC::ControlField.new('FMT')
    assert_equal(field.valid?, true)
    field = MARC::DataField.new('FMT')
    assert_equal(field.valid?, false)
    MARC::ControlField.control_tags.delete('FMT')
    field = MARC::DataField.new('FMT')
    assert_equal(field.valid?, true)
    field = MARC::ControlField.new('FMT')
    assert_equal(field.valid?, false)
  end

  def test_control_as_field
    # can't have a control with a tag > 009
    f = MARC::ControlField.new('245')
    assert_equal(f.valid?, false)
  end
end
