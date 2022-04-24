require "test/unit"
require "marc"

require "marc/marc8/to_unicode"

require "unf"

if "".respond_to?(:encoding)

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

      expected = UNF::Normalizer.normalize("Conversação", :nfc)

      assert_equal expected, value
    end

    def test_lots_of_marc8_test_cases
      # Heap of test cases taken from pymarc, which provided these
      # two data files, marc8 and utf8, with line-by-line correspondences.
      #
      # For now, we have NOT included proprietary III encodings in our test data!
      utf8_file = File.open(File.expand_path("../data/test_utf8.txt", __FILE__), "r:UTF-8")
      marc8_file = File.open(File.expand_path("../data/test_marc8.txt", __FILE__), "r:binary")

      i = 0
      converter = MARC::Marc8::ToUnicode.new

      begin
        loop do
          i += 1

          utf8 = utf8_file.readline.chomp
          marc8 = marc8_file.readline.chomp

          converted = converter.transcode(marc8)

          assert_equal "UTF-8", converted.encoding.name, "Converted data line #{i} is tagged UTF-8"
          assert converted.valid_encoding?, "Converted data line #{i} is valid_encoding"

          assert_equal utf8, converted, "Test data line #{i}, expected converted to match provided utf8"
        end
      rescue EOFError
        # just means the file was over, no biggie
        assert i > 1500, "Read as many lines as we expected to, at least 1500"
      rescue => e
        warn "Error at test data line #{i}"
        raise e
      end
    end

    def test_explicit_normalization
      # \xC1 is Marc8 "script small letter l", which under unicode
      # COMPAT normalization will turn into ordinary 'l'
      marc8 = "Conversa\xF0c\xE4ao \xC1"
      unicode = "Conversação \u2113"

      unicode_c = UNF::Normalizer.normalize(unicode, :nfc)
      unicode_kc = UNF::Normalizer.normalize(unicode, :nfkc)
      unicode_d = UNF::Normalizer.normalize(unicode, :nfd)
      unicode_kd = UNF::Normalizer.normalize(unicode, :nfkd)

      converter = MARC::Marc8::ToUnicode.new

      assert_equal unicode_c, converter.transcode(marc8, normalization: :nfc)
      assert_equal unicode_kc, converter.transcode(marc8, normalization: :nfkc)
      assert_equal unicode_d, converter.transcode(marc8, normalization: :nfd)
      assert_equal unicode_kd, converter.transcode(marc8, normalization: :nfkd)

      # disable normalization for performance or something, we won't end up with NFC.
      refute_equal unicode_c, converter.transcode(marc8, normalization: nil)
    end

    def test_expand_ncr
      converter = MARC::Marc8::ToUnicode.new

      marc8_ncr = "Weird &#x200F; &#xFFFD; but these aren't changed #x2000; &#200F etc."
      assert_equal "Weird \u200F \uFFFD but these aren't changed #x2000; &#200F etc.", converter.transcode(marc8_ncr)
      assert_equal marc8_ncr, converter.transcode(marc8_ncr, expand_ncr: false), "should not expand NCR if disabled"
    end

    def test_bad_byte
      converter = MARC::Marc8::ToUnicode.new

      bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
      assert_raise(Encoding::InvalidByteSequenceError) {
        converter.transcode(bad_marc8)
      }
    end

    def test_bad_byte_error_message
      converter = MARC::Marc8::ToUnicode.new

      bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
      begin
        converter.transcode(bad_marc8)
      rescue Encoding::InvalidByteSequenceError => err
        assert_equal("MARC8, input byte offset 30, code set: 0x31, code point: 0x7b3639, value: 米国の統治の仕組�", err.message)
      end
    end

    def test_multiple_bad_byte_error_message
      converter = MARC::Marc8::ToUnicode.new

      bad_marc8 = "\e$1!Q1!G4i$N!0p!Q+{6924f6}\e(B \e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B \e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
      begin
        converter.transcode(bad_marc8)
      rescue Encoding::InvalidByteSequenceError => err
        # It still identifies the first bad byte found in the offset info, but replaces all bad bytes in the error message
        assert_equal("MARC8, input byte offset 21, code set: 0x31, code point: 0x7b3639, value: 統治の仕組� 米国の統治の仕組� 米国の統治の仕組�", err.message)
      end
    end

    def test_bad_byte_with_replacement
      converter = MARC::Marc8::ToUnicode.new

      bad_marc8 = "\e$1!PVK7oi$N!Q1!G4i$N!0p!Q+{6924f6}\e(B"
      value = converter.transcode(bad_marc8, invalid: :replace)

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
      value = converter.transcode(bad_marc8, invalid: :replace, replace: "")

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

      assert_equal "La Soci\u00E9t\x1B,", value
    end
  end
else
  require "pathname"
  warn "\nTests not being run in ruby 1.9.x, skipping #{Pathname.new(__FILE__).basename}\n\n"
end
