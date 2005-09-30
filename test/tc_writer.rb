require 'test/unit'
require 'marc'

class WriterTest < Test::Unit::TestCase

    def test_encode()
        before = MARC::Record.new()
        before.append(MARC::Field.new('245', '0', '1', ['a','foo']))
        raw = before.encode()

        after = MARC::Record::decode(raw)
        assert_equal(after['245'].to_s, '245 01 $afoo')
    end

end
