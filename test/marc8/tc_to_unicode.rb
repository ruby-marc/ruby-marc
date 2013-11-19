# encoding: UTF-8

require 'test/unit'
require 'marc'

require 'marc/marc8/to_unicode'

require 'unf'

class TestMarc8ToUnicode < Test::Unit::TestCase
  def test_empty_string
    value = MARC::Marc8::ToUnicode.new.transcode("")
    assert_equal "UTF-8", value.encoding.name
    assert_equal "", value

    value = MARC::Marc8::ToUnicode.new.transcode(nil)
    assert_equal "UTF-8", value.encoding.name
    assert_equal "", value
  end

  def test_one_example_marc8
    value = MARC::Marc8::ToUnicode.new.transcode("Conversa\xF0c\xE4ao")
    assert_equal "UTF-8", value.encoding.name
    # decomposed UTF-8 version we know it makes right now; 
    # in future, may have to change this to normalize before test?

    assert_equal "Conversação", value
  end

  def test_lots_of_marc8_test_cases
    # Heap of test cases taken from pymarc, which provided these
    # two data files, marc8 and utf8, with line-by-line correspondences. 
    #
    # For now, we have NOT included proprietary III encodings in our test data! 
    utf8_file   = File.open( File.expand_path("../data/test_utf8.txt", __FILE__), "r:UTF-8")
    marc8_file  = File.open( File.expand_path("../data/test_marc8.txt", __FILE__), "r:binary")

    i = 0
    converter = MARC::Marc8::ToUnicode.new

    begin
      while true do
        i += 1

        utf8      = utf8_file.readline.chomp
        marc8     = marc8_file.readline.chomp

        converted = converter.transcode(marc8)
        # normalize it to NFC, our converter may not do that itself, but
        # our expected data is all in NFC. 
        converted = UNF::Normalizer.normalize(converted, :nfc)

        assert_equal "UTF-8", converted.encoding.name, "Converted data line #{i} is tagged UTF-8"
        assert converted.valid_encoding?, "Converted data line #{i} is valid_encoding"

        assert_equal utf8, converted, "Test data line #{i}, expected converted to match provided utf8"
      end
    rescue EOFError => each 
      # just means the file was over, no biggie
      assert i > 1500, "Read as many lines as we expected to, at least 1500"
    rescue Exception => e
      $stderr.puts "Error at test data line #{i}"
      raise e
    end
  end

  def test_bad_byte
    converter = MARC::Marc8::ToUnicode.new

    bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
    assert_raise(Encoding::InvalidByteSequenceError) {
      value = converter.transcode(bad_marc8)
    }
  end

  def test_bad_byte_with_replacement
    converter = MARC::Marc8::ToUnicode.new

    bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
    value = converter.transcode(bad_marc8, :invalid => :replace)

    assert_equal "UTF-8", value.encoding.name
    assert value.valid_encoding?

    assert value.include?("\uFFFD"), "includes replacement char"    
    # coalescing multiple replacement chars at end, could change
    # to not do so, important thing is at least one is there. 
    assert_equal "米国の統治の仕組�", value
  end

  def test_bad_byte_with_specified_empty_replacement
    converter = MARC::Marc8::ToUnicode.new

    bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
    value = converter.transcode(bad_marc8, :invalid => :replace, :replace => "")

    assert_equal "UTF-8", value.encoding.name
    assert value.valid_encoding?

    assert_equal "米国の統治の仕組", value
  end

  def test_bad_escape
    converter = MARC::Marc8::ToUnicode.new

    # I do not understand what's going on here, or why this is
    # desired/expected behavior.  But this
    # test is copied from pymarc , adapted to be straight data not marc record
    # https://github.com/edsu/pymarc/blob/master/test/marc8.py?source=cc#L34

    bad_escape_data = "La Soci\xE2et\e,"
    value = converter.transcode(bad_escape_data)

    assert_equal "UTF-8", value.encoding.name
    assert value.valid_encoding?, "Valid encoding"

    assert_equal "La Soci\u00E9t\x1B,", UNF::Normalizer.normalize(value, :nfc)
  end

end
