require 'test/unit'
require 'marc'

class ReaderTest < Test::Unit::TestCase

    def test_decode
        raw = IO.read('test/one.dat')
        r = MARC::Record::decode(raw)
        assert_equal(r.class, MARC::Record)
        assert_equal(r.leader,'00755cam  22002414a 45000')
        assert_equal(r.fields.length(), 18)
    end

    def test_encoder
    end

end
