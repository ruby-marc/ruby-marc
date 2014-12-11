# encoding: UTF-8

require_relative './test_helper'
require 'marc'

class TestField < Minitest::Test

  def test_control
    control = MARC::ControlField.new('005', 'foobarbaz')
    assert_equal(control.to_s, '005 foobarbaz')
  end

  def test_field_as_control
    assert_raises(MARC::Exception) do
      # can't have a field with a tag < 010
      field = MARC::DataField.new('007')
    end
  end

  def test_alpha_control_field
    assert_raises(MARC::Exception) do
      # can't have a field with a tag < 010
      field = MARC::ControlField.new('DDD')
    end
  end

  def test_extra_control_field
    MARC::ControlField.control_tags << 'FMT'
    begin
      field = MARC::ControlField.new('FMT')
      assert_equal(true, true, "FMT added as legal control field")
    rescue => e
      refute_equal(true, true, "FMT added as legal control field")
    end


    assert_raises(MARC::Exception) do
      field = MARC::DataField.new('FMT')
    end
    MARC::ControlField.control_tags.delete('FMT')
    begin
      field = MARC::DataField.new('FMT')
      assert_equal(true, true, "FMT removed as legal control field")
    rescue => e
      refute_equal(true, true, "FMT removed as legal control field")
    end
    assert_raises(MARC::Exception) do
      field = MARC::ControlField.new('FMT')
    end

  end

  def test_control_as_field
    assert_raises(MARC::Exception) do
      # can't have a control with a tag > 009
      f = MARC::ControlField.new('245')
    end
  end
end

