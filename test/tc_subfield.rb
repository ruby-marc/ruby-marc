require 'test/unit'
require 'marc/subfield'

class SubfieldTest < Test::Unit::TestCase

  def test_ok
    s = MARC::Subfield.new('a', 'foo')
    assert_equal(s.code, 'a')
    assert_equal(s.value, 'foo')
  end

  def test_equals
    s1 = MARC::Subfield.new('a', 'foo')
    s2 = MARC::Subfield.new('a', 'foo')
    assert_equal(s1, s2)

    assert_not_equal(s1, 'a')
    assert_not_equal(s1, 'foo')
  end

end
