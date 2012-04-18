# -*- encoding: utf-8 -*-

require 'test/unit'
require 'marc'

# Testing char encodings under 1.9, don't bother running
# these tests except under 1.9, will either fail (because
# 1.9 func the test itself uses isn't there), or trivially pass
# (becuase the func they are testing is no-op on 1.9).

if "".respond_to?(:encoding)
  
  class ReaderCharEncodingsTest < Test::Unit::TestCase
  
    def test_unicode_load
      reader = MARC::Reader.new('test/utf8.marc')
      
      record = nil
      
      assert_nothing_raised { record = reader.first }
      
      assert_equal "UTF-8", record['245']['a'].encoding.name
      assert record['245']['a'].start_with?("Photčhanānukrom")
    end
  
    def test_explicit_encoding
      reader = MARC::Reader.new('test/cp866.marc', :external_encoding => 'cp866')
      assert_equal(["d09d"], reader.first['001'].value.encode('utf-8').unpack('H4')) # russian capital N
    end
  
    def test_load_file_opened_with_external_encoding
      reader = MARC::Reader.new(File.open('test/cp866.marc', 'r:cp866'))
      
      record = reader.first  
      # Make sure it's got the encoding it's supposed to. 
      assert_equal("IBM866", record['001'].value.encoding.name )
      assert_equal(["d09d"], record['001'].value.encode('utf-8').unpack('H4')) # russian capital N
    end
    
    def test_explicit_encoding_beats_file_encoding
      reader = MARC::Reader.new(File.open('test/cp866.marc', 'r:utf-8'), :external_encoding => "cp866")
      
      record = reader.first
      assert_equal("IBM866", record['001'].value.encoding.name )
      assert_equal(["d09d"], record['001'].value.encode('utf-8').unpack('H4')) # russian capital N
    end
    
    def test_from_string_with_utf8_encoding
      marc_string = File.open('test/utf8.marc').read.force_encoding("UTF-8")
      
      reader = MARC::Reader.new(StringIO.new(marc_string))
      record = reader.first
      
      assert_equal "UTF-8", record['245']['a'].encoding.name
      assert_equal "UTF-8", record['245'].subfields.first.value.encoding.name
      
      assert record['245']['a'].start_with?("Photčhanānukrom")
    end
    
    def test_from_string_with_cp866
      marc_string = File.open('test/cp866.marc').read.force_encoding("cp866")
      
      reader = MARC::Reader.new(StringIO.new(marc_string))
      record = reader.first
      
      assert_equal("IBM866", record['001'].value.encoding.name )
      assert_equal(["d09d"], record['001'].value.encode('utf-8').unpack('H4')) # russian capital N
    end
    
    def test_decode_from_string_with_cp866
      marc_string = File.open('test/cp866.marc').read.force_encoding("cp866")
      
      record = MARC::Reader.decode(marc_string)
      
      assert_equal("IBM866", record['001'].value.encoding.name )
      assert_equal(["d09d"], record['001'].value.encode('utf-8').unpack('H4')) # russian capital N
    end
    
    def test_with_transcode
      reader = MARC::Reader.new('test/cp866.marc', 
        :external_encoding => 'cp866', 
        :internal_encoding => 'UTF-8')
      
      record = reader.first 
    
      assert_equal('UTF-8', record['001'].value.encoding.name)
      assert_equal(["d09d"], record['001'].value.unpack('H4')) # russian capital N
    end
    
    def test_with_bad_source_bytes
      reader = MARC::Reader.new('test/utf8_with_bad_bytes.marc', 
        :external_encoding => "UTF-8")
      
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
  end
else
  require 'pathname'
  $stderr.puts "\nTests not being run in ruby 1.9.x, skipping #{Pathname.new(__FILE__).basename}\n\n"  
end
