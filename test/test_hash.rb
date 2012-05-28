require 'test/unit'
require 'marc'
require 'rubygems'

class TestHash < Test::Unit::TestCase

  def test_to_hash
    raw = IO.read('test/one.dat')
    r = MARC::Record.new_from_marc(raw)
    h = r.to_hash
    assert_kind_of(Hash, h)
    assert_equal(r.leader, h['leader'])
    assert_equal(r.fields.length, h['fields'].length)
    assert_equal(r.fields.first.tag, h['fields'].first.keys.first)
  end

  def test_roundtrip
    reader = MARC::Reader.new('test/batch.dat')
    reader.each do |r|
      x = MARC::Record.new_from_hash(r.to_hash)
      assert_equal(r,x)
    end
  end
  
  
end