require 'test/unit'
require 'marc'

require 'stringio'

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

    # Only in ruby 1.9
    if "".respond_to?(:encoding)
      def test_writer_bad_encoding
        writer = MARC::Writer.new('test/writer.dat')


        # MARC::Writer should just happily write out whatever bytes you give it, even
        # mixing encodings that can't be mixed. We ran into an actual example mixing
        # MARC8 (tagged ruby binary) and UTF8, we want it to be written out. 

        record = MARC::Record.new

        record.append MARC::DataField.new('700', '0', ' ', ['a', "Nhouy Abhay,".force_encoding("BINARY")], ["c", "Th\xE5ao,".force_encoding("BINARY")], ["d", "1909-"])
        record.append MARC::DataField.new('700', '0', ' ', ['a', "Somchin P\xF8\xE5o. Ngin,".force_encoding("BINARY")])

        record.append MARC::DataField.new('100', '0', '0', ['a', "\xE5angkham. ".force_encoding("BINARY")])
        record.append MARC::DataField.new('245', '1', '0', ['b', "chef-d'oeuvre de la litt\xE2erature lao".force_encoding("BINARY")])

        # One in UTF8 and marked 
        record.append MARC::DataField.new('999', '0', '1', ['a', "chef-d'ocuvre de la littU+FFC3\U+FFA9rature".force_encoding("UTF-8")])

        writer.write(record)
        writer.close

      ensure 
          File.unlink('test/writer.dat')
      end
    end

    def test_write_too_long_iso2709
      too_long_record = MARC::Record.new
      1.upto(1001) do
        too_long_record.append MARC::DataField.new("500", ' ', ' ', ['a', 'A really long record.1234567890123456789012345678901234567890123456789012345678901234567890123456789'])
      end

      wbuffer = StringIO.new("", "w")
      writer = MARC::Writer.new(wbuffer)

      writer.write(too_long_record)
      writer.close

      assert_equal "00000", wbuffer.string.slice(0, 5), "zero'd out length bytes when too long"

      rbuffer = StringIO.new(wbuffer.string.dup)

      # Regular reader won't read our illegal record.
      #assert_raise(NoMethodError) do
      #  reader = MARC::Reader.new(rbuffer)
      #  reader.first
      #end

      # Forgiving reader will, round trippable
      new_record = MARC::Reader.decode(rbuffer.string, :forgiving => true)      
      assert_equal too_long_record, new_record, "Too long record round-trippable with forgiving mode"

      # Test in the middle of a MARC file
      good_record = MARC::Record.new
      good_record.append MARC::DataField.new("500", ' ', ' ', ['a', 'A short record'])
      wbuffer = StringIO.new("", "w")
      writer = MARC::Writer.new(wbuffer)

      writer.write(good_record)
      writer.write(too_long_record)
      writer.write(good_record)

      rbuffer = StringIO.new(wbuffer.string.dup)
      reader  = MARC::ForgivingReader.new(rbuffer)
      records = reader.to_a

      assert_equal 3, records.length
      assert_equal good_record, records[0]
      assert_equal good_record, records[2]
      assert_equal too_long_record, records[1]
    end

    def test_raises_on_too_long_if_configured
      too_long_record = MARC::Record.new
      1.upto(1001) do
        too_long_record.append MARC::DataField.new("500", ' ', ' ', ['a', 'A really long record.1234567890123456789012345678901234567890123456789012345678901234567890123456789'])
      end

      wbuffer = StringIO.new("", "w")
      writer = MARC::Writer.new(wbuffer)
      writer.allow_oversized = false

      assert_raise(MARC::Exception) do
        writer.write too_long_record
      end

    end

    
    def test_forgiving_writer
      marc = "00305cam a2200133 a 4500001000700000003000900007005001700016008004100033008004100074035002500115245001700140909001000157909000400167\036635145\036UK-BiLMS\03620060329173705.0\036s1982iieng6                  000 0 eng||\036060116|||||||||xxk                 eng||\036  \037a(UK-BiLMS)M0017366ZW\03600\037aTest record.\036  \037aa\037b\037c\036\037b0\036\035\000"
      rec = MARC::Record.new_from_marc(marc)
      assert_nothing_raised do 
        rec.to_marc
      end
    end

    def test_unicode_roundtrip
      record = MARC::Reader.new('test/utf8.marc', :external_encoding => "UTF-8").first
      
      writer = MARC::Writer.new('test/writer.dat')      
      writer.write(record)      
      writer.close      
      
      read_back_record = MARC::Reader.new('test/writer.dat', :external_encoding => "UTF-8").first

      # Make sure the one we wrote out then read in again
      # is the same as the one we read the first time
      # Looks like "==" is over-ridden to do that. Don't ever change, #==
      assert_equal record, read_back_record, "Round-tripped record must equal original record"
    end
    

end
