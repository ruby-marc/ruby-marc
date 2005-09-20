require 'test/unit'
require 'marc'

class TestRecord < Test::Unit::TestCase

    def test_constructor
        r = MARC::Record.new()
        assert_equal(r.class, MARC::Record)
    end

    def test_append_field
        r = get_record()
        assert_equal(r.fields.length(), 2)
    end

    def test_iterator
        r = get_record()
        count = 0
        r.each {|f| count += 1}
        assert_equal(count,2)
    end

    def get_record
        r = MARC::Record.new()
        r.append(MARC::Field.new('100', '2', '0', ['a', 'Thomas, Dave'])) 
        r.append(MARC::Field.new('245', '0', '4', ['The Pragmatic Programmer']))
        return r
    end

end
