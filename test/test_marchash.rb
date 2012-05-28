require 'test/unit'
require 'marc'
require 'rubygems'

class TestMARCHASH < Test::Unit::TestCase

  def test_simple
    simple = {
      'type' => 'marc-hash',
      'version' => [1,0],
      'leader' => 'LEADER',
      'fields' => [
        ['245', '1', '0', 
          [
            ['a', 'TITLE'],
            ['b', 'SUBTITLE']
          ]
        ]
      ]
    }
    r = MARC::Record.new()
    r.leader = 'LEADER'
    f = MARC::DataField.new('245', '1', '0', ['a', 'TITLE'], ['b', 'SUBTITLE'])
    r << f
    assert_equal(r.to_marchash, simple)
  end

  def test_real
    reader = MARC::Reader.new('test/batch.dat')
    reader.each do |r|
      x = MARC::Record.new_from_marchash(r.to_marchash)
      assert_equal(r,x)
    end
  end
  
  
end