require 'test/unit'
require 'marc'

class WriterTest < Test::Unit::TestCase

    def test_writer
        writer = MARC::Writer.new('test/writer.dat')
        record = MARC::Record.new()
        record.append(MARC::DataField.new('245', '0', '1', ['a', 'foo']))
        writer.write(record)
        writer.close()

        # read it back to make sure
        reader = MARC::Reader.new('test/writer.dat')
        records = reader.entries()
        assert_equal(records.length(), 1)
        assert_equal(records[0], record)

        # cleanup
        File.unlink('test/writer.dat')
    end
    
    def test_forgiving_writer
      marc = "00305cam a2200133 a 4500001000700000003000900007005001700016008004100033008004100074035002500115245001700140909001000157909000400167\036635145\036UK-BiLMS\03620060329173705.0\036s1982iieng6                  000 0 eng||\036060116|||||||||xxk                 eng||\036  \037a(UK-BiLMS)M0017366ZW\03600\037aTest record.\036  \037aa\037b\037c\036\037b0\036\035\000"
      rec = MARC::Record.new_from_marc(marc)
      assert_nothing_raised do 
        rec.to_marc
      end
    end

    def test_ampersand
    end


end
