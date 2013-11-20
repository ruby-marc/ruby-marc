# -*- encoding: utf-8 -*-

require 'test/unit'
require 'marc'

require 'stringio'

# Testing char encodings under 1.9, don't bother running
# these tests except under 1.9, will either fail (because
# 1.9 func the test itself uses isn't there), or trivially pass
# (becuase the func they are testing is no-op on 1.9).

if "".respond_to?(:encoding)
  
  class ReaderCharEncodingsTest < Test::Unit::TestCase
    ####
    # Helper methods for our tests
    #
    ####
    
    
    @@utf_marc_path = 'test/utf8.marc'
    # tests against record at test/utf8.marc
    def assert_utf8_right_in_utf8(record)
      assert_equal "UTF-8", record['245'].subfields.first.value.encoding.name
            
      assert_equal "UTF-8", record['245'].to_s.encoding.name
      
      assert_equal "UTF-8", record['245'].subfields.first.to_s.encoding.name
      assert_equal "UTF-8", record['245'].subfields.first.value.encoding.name
      
      assert_equal "UTF-8", record['245']['a'].encoding.name
      assert record['245']['a'].start_with?("Photčhanānukrom")
    end
    
    # Test against multirecord just to be sure that works. 
    # the multirecord file is just two concatenated copies
    # of the single one. 
    @@cp866_marc_path = "test/cp866_multirecord.marc"
    # assumes record in test/cp866_unimarc.marc
    # Pass in an encoding name, using ruby's canonical name!
    # "IBM866" not "cp866". "UTF-8". 
    def assert_cp866_right(record, encoding = "IBM866")
      assert_equal(encoding, record['001'].value.encoding.name)
      assert_equal(["d09d"], record['001'].value.encode("UTF-8").unpack('H4')) # russian capital N    
    end

    @@bad_marc8_path = "test/bad_eacc_encoding.marc8.marc"
    

    def assert_all_values_valid_encoding(record, encoding_name="UTF-8")
      record.fields.each do |field|
        if field.kind_of? MARC::DataField
          field.subfields.each do |sf|
            assert_equal encoding_name, sf.value.encoding.name, "Is tagged #{encoding_name}: #{field.tag}: #{sf}"
            assert field.value.valid_encoding?, "Is valid encoding: #{field.tag}: #{sf}"
          end
        else
          assert_equal encoding_name, field.value.encoding.name, "Is tagged #{encoding_name}: #{field}"
          assert field.value.valid_encoding?, "Is valid encoding: #{field}"
        end
      end
    end

    ####
    # end helper methods
    ####
    
    
    def test_unicode_load
      reader = MARC::Reader.new(@@utf_marc_path)
      
      record = nil
      
      assert_nothing_raised { record = reader.first }
      
      assert_utf8_right_in_utf8(record)
    end
    
    
    def test_unicode_decode_forgiving
      # two kinds of forgiving invocation, they shouldn't be different,
      # but just in case they have slightly different code paths, test em
      # too. 
      marc_string = File.open(@@utf_marc_path).read.force_encoding("utf-8")      
      record = MARC::Reader.decode(marc_string, :forgiving => true)
      assert_utf8_right_in_utf8(record)

      
      reader = MARC::ForgivingReader.new(@@utf_marc_path)
      record = reader.first
      assert_utf8_right_in_utf8(record)
    end
    
    def test_unicode_forgiving_reader_passes_options
      # Make sure ForgivingReader accepts same options as MARC::Reader
      # We don't test them ALL though, just a sample.
      # Tell it we're reading cp866, but trancode to utf8 for us. 
      reader = MARC::ForgivingReader.new(@@cp866_marc_path, :external_encoding => "cp866", :internal_encoding => "utf-8")

      record = reader.first 

      assert_cp866_right(record, "UTF-8")
    end
  
    def test_explicit_encoding
      reader = MARC::Reader.new(@@cp866_marc_path, :external_encoding => 'cp866')
      
      assert_cp866_right(reader.first, "IBM866")
    end
    
    def test_bad_encoding_name_input
      reader = MARC::Reader.new(@@cp866_marc_path, :external_encoding => 'adadfadf')
      assert_raises ArgumentError do
        reader.first
      end
    end
    
    def test_marc8_with_binary
      # Marc8, if we want to keep it without transcoding, best we can do is read it in binary. 
      reader = MARC::Reader.new('test/marc8_accented_chars.marc', :external_encoding => 'binary')
      record = reader.first
   
      assert_equal "ASCII-8BIT", record['100'].subfields.first.value.encoding.name
    end

    def test_marc8_converted_to_unicode
      reader = MARC::Reader.new('test/marc8_accented_chars.marc', :external_encoding => 'MARC-8')
      record = reader.first

      assert_all_values_valid_encoding(record)

      assert_equal "Serreau, Geneviève.", record['100']['a']
    end

    def test_marc8_converted_to_unicode_with_file_handle
      # had some trouble with this one, let's ensure it with a test
      file    = File.new('test/marc8_accented_chars.marc')
      reader  = MARC::Reader.new(file, :external_encoding => "MARC-8")
      record  =  reader.first

      assert_all_values_valid_encoding(record)
    end

    def test_marc8_with_char_entity
      reader = MARC::Reader.new("test/escaped_character_reference.marc8.marc", :external_encoding => "MARC-8")
      record = reader.first

      assert_all_values_valid_encoding(record)

      assert_equal "Rio de Janeiro escaped replacement char: \uFFFD .", record['260']['a']
    end

    def test_bad_marc8_raises
      assert_raise(Encoding::InvalidByteSequenceError) do
        reader = MARC::Reader.new(@@bad_marc8_path, :external_encoding => 'MARC-8')
        record = reader.first
      end
    end

    def test_bad_marc8_with_replacement
      reader = MARC::Reader.new(@@bad_marc8_path, :external_encoding => 'MARC-8', :invalid => :replace, :replace => "[?]")
      record = reader.first

      assert_all_values_valid_encoding(record)      
      
      assert record['880']['a'].include?("[?]"), "includes specified replacement string"
    end


    def test_load_file_opened_with_external_encoding
      reader = MARC::Reader.new(File.open(@@cp866_marc_path, 'r:cp866'))
      
      record = reader.first  
      # Make sure it's got the encoding it's supposed to.
      
      assert_cp866_right(record, "IBM866")      
    end
    
    def test_explicit_encoding_beats_file_encoding
      reader = MARC::Reader.new(File.open(@@cp866_marc_path, 'r:utf-8'), :external_encoding => "cp866")
      
      record = reader.first
      
      assert_cp866_right(record, "IBM866")            
    end
    
    def test_from_string_with_utf8_encoding
      marc_file = File.open(@@utf_marc_path)
      
      reader = MARC::Reader.new(marc_file)
      record = reader.first
      



    end

    # Something that was failing in my client Blacklight code,
    # bad bytes should be handled appropriately
    def test_from_string_utf8_with_bad_byte
      marc_file = File.open('test/marc_with_bad_utf8.utf8.marc')
      
      reader = MARC::Reader.new(marc_file, :invalid => :replace)

      record = reader.first

      record.fields.each do |field|
        if field.kind_of? MARC::ControlField
          assert_equal "UTF-8", field.value.encoding.name
          assert field.value.valid_encoding?
        else
          field.subfields.each do |subfield|
            assert_equal "UTF-8", subfield.value.encoding.name
            assert subfield.value.valid_encoding?, "value has valid encoding"
          end
        end
      end

      assert record['520']['a'].include?("\uFFFD"), "Value with bad byte now has Unicode Replacement Char"
    end
    
    def test_from_string_with_cp866
      marc_string = File.open(@@cp866_marc_path).read.force_encoding("cp866")
      
      reader = MARC::Reader.new(StringIO.new(marc_string))
      record = reader.first
      
      assert_cp866_right(record, "IBM866")      
    end
    
    def test_decode_from_string_with_cp866
      marc_string = File.open(@@cp866_marc_path).read.force_encoding("cp866")
      
      record = MARC::Reader.decode(marc_string)
      
      assert_cp866_right(record, "IBM866")      
    end
    
    def test_with_transcode
      reader = MARC::Reader.new(@@cp866_marc_path, 
        :external_encoding => 'cp866', 
        :internal_encoding => 'UTF-8')
      
      record = reader.first 
    
      assert_cp866_right(record, "UTF-8")      
      
    end
    
    def test_with_binary_filehandle
      # about to recommend this as a foolproof way to avoid
      # ruby transcoding behind your back in docs, let's make
      # sure it really works. 
      reader = MARC::Reader.new(File.open(@@cp866_marc_path, :external_encoding => "binary", :internal_encoding => "binary"),
        :external_encoding => "IBM866")
        
      record = reader.first
      assert_cp866_right(record, "IBM866")
    end
    
    def test_with_bad_source_bytes
      reader = MARC::Reader.new('test/utf8_with_bad_bytes.marc', 
        :external_encoding => "UTF-8",
        :validate_encoding => true)
      
      assert_raise Encoding::InvalidByteSequenceError do
        record = reader.first
      end
    end
    
    def test_bad_source_bytes_with_replace
      reader = MARC::Reader.new('test/utf8_with_bad_bytes.marc', 
        :external_encoding => "UTF-8", :invalid => :replace)
      
      record = nil
      assert_nothing_raised do
        record = reader.first
      end
      
      # it should have the unicode replacement char where the bad
      # byte was. 
      assert_match '=> ' +  "\uFFFD" + '( <=', record['245']['a']      
    end
    
    def test_bad_source_bytes_with_custom_replace
      reader = MARC::Reader.new('test/utf8_with_bad_bytes.marc', 
        :external_encoding => "UTF-8", :invalid => :replace, :replace => '')
      
      record = reader.first
      
      # bad byte replaced with empty string, gone.     
      assert_match '=> ( <=', record['245']['a']
      
    end
    
    def test_default_internal_encoding      
      # Some people WILL be changing their Encoding.default_internal
      # It's even recommended by wycats 
      # http://yehudakatz.com/2010/05/05/ruby-1-9-encodings-a-primer-and-the-solution-for-rails/
      # This will in some cases make ruby File object trans-code
      # by default. Trans-coding a serial marc binary can change the
      # byte count and mess it up. 
      #
      # But at present, because of the way the Reader is implemented reading
      # specific bytecounts, it _works_, although it does not _respect_
      # Encoding.default_internal. That's the best we can do right now,
      # thsi test is important to ensure it stays at least this good. 
       begin
         original = Encoding.default_internal
         Encoding.default_internal = "UTF-8"
         
         reader = MARC::Reader.new(File.open(@@cp866_marc_path, 'r:cp866'))
       
         record = reader.first
         
         assert_cp866_right(record, "IBM866")                        
       ensure
         Encoding.default_internal = original
       end      
    end
    
    def test_default_internal_encoding_with_string_arg
      begin
         original = Encoding.default_internal
         Encoding.default_internal = "UTF-8"
         
         reader = MARC::Reader.new(@@cp866_marc_path, :external_encoding => "cp866")
       
         record = reader.first
         
         assert_cp866_right(record, "IBM866")                        
       ensure
         Encoding.default_internal = original
       end    
    end
      
  end
  
  
  
else
  require 'pathname'
  $stderr.puts "\nTests not being run in ruby 1.9.x, skipping #{Pathname.new(__FILE__).basename}\n\n"  
end
