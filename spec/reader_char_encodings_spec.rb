require 'spec_helper'
require 'stringio'

# Testing char encodings under 1.9, don't bother running
# these tests except under 1.9, will either fail (because
# 1.9 func the test itself uses isn't there), or trivially pass
# (because the func they are testing is no-op on 1.9).

if "".respond_to?(:encoding)
  RSpec.describe "Reader Character Encodings" do
    # Common test files
    let(:utf_marc_path) { "test/utf8.marc" }
    let(:cp866_marc_path) { "test/cp866_multirecord.marc" }
    let(:bad_marc8_path) { "test/bad_eacc_encoding.marc8.marc" }
    
    # Helper methods
    def assert_utf8_right_in_utf8(record)
      expect(record["245"].subfields.first.value.encoding.name).to eq("UTF-8")
      expect(record["245"].to_s.encoding.name).to eq("UTF-8")
      expect(record["245"].subfields.first.to_s.encoding.name).to eq("UTF-8")
      expect(record["245"].subfields.first.value.encoding.name).to eq("UTF-8")
      expect(record["245"]["a"].encoding.name).to eq("UTF-8")
      expect(record["245"]["a"]).to start_with("Photčhanānukrom")
    end

    def assert_cp866_right(record, encoding = "IBM866")
      expect(record["001"].value.encoding.name).to eq(encoding)
      expect(record["001"].value.encode("UTF-8").unpack("H4")).to eq(["d09d"]) # russian capital N
    end

    def assert_all_values_valid_encoding(record, encoding_name = "UTF-8")
      record.fields.each do |field|
        if field.is_a? MARC::DataField
          field.subfields.each do |sf|
            expect(sf.value.encoding.name).to eq(encoding_name), "Is tagged #{encoding_name}: #{field.tag}: #{sf}"
            expect(field.value.valid_encoding?).to be(true), "Is valid encoding: #{field.tag}: #{sf}"
          end
        else
          expect(field.value.encoding.name).to eq(encoding_name), "Is tagged #{encoding_name}: #{field}"
          expect(field.value.valid_encoding?).to be(true), "Is valid encoding: #{field}"
        end
      end
    end

    it "loads unicode correctly" do
      reader = MARC::Reader.new(utf_marc_path)
      record = nil
      expect { record = reader.first }.not_to raise_error
      assert_utf8_right_in_utf8(record)
    end

    it "decodes unicode with forgiving mode" do
      # two kinds of forgiving invocation, they shouldn't be different,
      # but just in case they have slightly different code paths, test em too.
      marc_string = File.read(utf_marc_path).force_encoding("utf-8")
      record = MARC::Reader.decode(marc_string, forgiving: true)
      assert_utf8_right_in_utf8(record)

      reader = MARC::ForgivingReader.new(utf_marc_path)
      record = reader.first
      assert_utf8_right_in_utf8(record)
    end

    it "passes options through ForgivingReader" do
      # Make sure ForgivingReader accepts same options as MARC::Reader
      # We don't test them ALL though, just a sample.
      # Tell it we're reading cp866, but trancode to utf8 for us.
      reader = MARC::ForgivingReader.new(cp866_marc_path, external_encoding: "cp866", internal_encoding: "utf-8")
      record = reader.first
      assert_cp866_right(record, "UTF-8")
    end

    it "handles explicit encoding" do
      reader = MARC::Reader.new(cp866_marc_path, external_encoding: "cp866")
      assert_cp866_right(reader.first, "IBM866")
    end

    it "raises error on bad encoding name" do
      reader = MARC::Reader.new(cp866_marc_path, external_encoding: "adadfadf")
      expect { reader.first }.to raise_error(ArgumentError)
    end

    it "handles marc8 with binary encoding" do
      # Marc8, if we want to keep it without transcoding, best we can do is read it in binary.
      reader = MARC::Reader.new("test/marc8_accented_chars.marc", external_encoding: "binary")
      record = reader.first
      expect(record["100"].subfields.first.value.encoding.name).to eq("ASCII-8BIT")
    end

    it "converts marc8 to unicode" do
      reader = MARC::Reader.new("test/marc8_accented_chars.marc", external_encoding: "MARC-8")
      record = reader.first
      assert_all_values_valid_encoding(record)
      expect(record["100"]["a"]).to eq("Serreau, Geneviève.")
    end

    it "converts marc8 to unicode with file handle" do
      # had some trouble with this one, let's ensure it with a test
      file = File.new("test/marc8_accented_chars.marc")
      reader = MARC::Reader.new(file, external_encoding: "MARC-8")
      record = reader.first
      assert_all_values_valid_encoding(record)
    end

    it "handles marc8 with character entities" do
      reader = MARC::Reader.new("test/escaped_character_reference.marc8.marc", external_encoding: "MARC-8")
      record = reader.first
      assert_all_values_valid_encoding(record)
      expect(record["260"]["a"]).to eq("Rio de Janeiro escaped replacement char: \uFFFD .")
    end

    it "raises error on bad marc8" do
      expect {
        reader = MARC::Reader.new(bad_marc8_path, external_encoding: "MARC-8")
        reader.first
      }.to raise_error(Encoding::InvalidByteSequenceError)
    end

    it "handles bad marc8 with replacement" do
      reader = MARC::Reader.new(bad_marc8_path, external_encoding: "MARC-8", invalid: :replace, replace: "[?]")
      record = reader.first
      assert_all_values_valid_encoding(record)
      expect(record["880"]["a"]).to include("[?]")
    end

    it "handles files opened with external encoding" do
      reader = MARC::Reader.new(File.open(cp866_marc_path, "r:cp866"))
      record = reader.first
      assert_cp866_right(record, "IBM866")
    end

    it "prioritizes explicit encoding over file encoding" do
      reader = MARC::Reader.new(File.open(cp866_marc_path, "r:utf-8"), external_encoding: "cp866")
      record = reader.first
      assert_cp866_right(record, "IBM866")
    end

    it "handles strings with utf8 encoding" do
      marc_file = File.open(utf_marc_path)
      reader = MARC::Reader.new(marc_file)
      expect { reader.first }.not_to raise_error
    end

    it "handles utf8 with bad bytes" do
      marc_file = File.open("test/marc_with_bad_utf8.utf8.marc")
      reader = MARC::Reader.new(marc_file, invalid: :replace)
      record = reader.first

      record.fields.each do |field|
        if field.is_a? MARC::ControlField
          expect(field.value.encoding.name).to eq("UTF-8")
          expect(field.value.valid_encoding?).to be(true)
        else
          field.subfields.each do |subfield|
            expect(subfield.value.encoding.name).to eq("UTF-8")
            expect(subfield.value.valid_encoding?).to be(true)
          end
        end
      end

      expect(record["520"]["a"]).to include("\uFFFD")
    end

    it "handles string with cp866 encoding" do
      marc_string = File.read(cp866_marc_path).force_encoding("cp866")
      reader = MARC::Reader.new(StringIO.new(marc_string))
      record = reader.first
      assert_cp866_right(record, "IBM866")
    end

    it "decodes strings with cp866 encoding" do
      marc_string = File.read(cp866_marc_path).force_encoding("cp866")
      record = MARC::Reader.decode(marc_string)
      assert_cp866_right(record, "IBM866")
    end

    it "supports transcoding" do
      reader = MARC::Reader.new(cp866_marc_path,
        external_encoding: "cp866",
        internal_encoding: "UTF-8")
      record = reader.first
      assert_cp866_right(record, "UTF-8")
    end

    it "works with binary filehandle" do
      # about to recommend this as a foolproof way to avoid
      # ruby transcoding behind your back in docs, let's make
      # sure it really works.
      reader = MARC::Reader.new(File.open(cp866_marc_path, external_encoding: "binary", internal_encoding: "binary"),
        external_encoding: "IBM866")
      record = reader.first
      assert_cp866_right(record, "IBM866")
    end

    it "handles bad source bytes" do
      reader = MARC::Reader.new("test/utf8_with_bad_bytes.marc",
        external_encoding: "UTF-8",
        validate_encoding: true)
      expect { reader.first }.to raise_error(Encoding::InvalidByteSequenceError)
    end

    it "replaces bad source bytes when configured" do
      reader = MARC::Reader.new("test/utf8_with_bad_bytes.marc",
        external_encoding: "UTF-8", invalid: :replace)
      record = nil
      expect { record = reader.first }.not_to raise_error
      expect(record["245"]["a"]).to match(/=> #{"\uFFFD"} \(<=/)
    end

    it "supports custom replacement for bad bytes" do
      reader = MARC::Reader.new("test/utf8_with_bad_bytes.marc",
        external_encoding: "UTF-8", invalid: :replace, replace: "")
      record = reader.first
      expect(record["245"]["a"]).to match(/=> \( <=/)
    end

    it "works with default_internal encoding" do
      original = Encoding.default_internal
      Encoding.default_internal = "UTF-8"

      reader = MARC::Reader.new(File.open(cp866_marc_path, "r:cp866"))
      record = reader.first
      assert_cp866_right(record, "IBM866")
    ensure
      Encoding.default_internal = original
    end

    it "works with default_internal encoding using string arg" do
      original = Encoding.default_internal
      Encoding.default_internal = "UTF-8"

      reader = MARC::Reader.new(cp866_marc_path, external_encoding: "cp866")
      record = reader.first
      assert_cp866_right(record, "IBM866")
    ensure
      Encoding.default_internal = original
    end
  end
else
  RSpec.describe "Reader Character Encodings" do
    it "skips tests on Ruby < 1.9" do
      skip("Tests not being run in ruby 1.9.x or higher")
    end
  end
end
