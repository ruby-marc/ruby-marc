# encoding: UTF-8

require_relative './test_helper'
require 'marc'

class ParsersTest < Minitest::Test
  def test_parser_default
    assert_equal("rexml", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
  end

  def test_set_nokogiri
    begin
      require 'nokogiri'
      assert_equal("rexml", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(REXML::Parsers::PullParser, reader.parser)
      reader = MARC::XMLReader.new('test/one.xml', :parser=>MARC::XMLReader::USE_NOKOGIRI)
      assert_kind_of(Nokogiri::XML::SAX::Parser, reader.parser)
      assert_equal("rexml", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml', :parser=>'nokogiri')
      assert_kind_of(Nokogiri::XML::SAX::Parser, reader.parser)
      assert_equal("rexml", MARC::XMLReader.parser)
      MARC::XMLReader.parser=MARC::XMLReader::USE_NOKOGIRI
      assert_equal("nokogiri", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(Nokogiri::XML::SAX::Parser, reader.parser)
      MARC::XMLReader.parser="nokogiri"
      assert_equal("nokogiri", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(Nokogiri::XML::SAX::Parser, reader.parser)
    rescue LoadError
      puts "\nNokogiri not available, skipping 'test_set_nokogiri'.\n"
    end
  end

  def test_set_jrexml
    if defined? JRUBY_VERSION
      begin
        require 'jrexml'
        reader = MARC::XMLReader.new('test/one.xml', :parser=>MARC::XMLReader::USE_JREXML)
        assert_kind_of(REXML::Parsers::PullParser, reader.parser)
        assert_equal("rexml", MARC::XMLReader.parser)
        reader = MARC::XMLReader.new('test/one.xml', :parser=>'jrexml')
        assert_kind_of(REXML::Parsers::PullParser, reader.parser)
        assert_equal("rexml", MARC::XMLReader.parser)
        MARC::XMLReader.parser=MARC::XMLReader::USE_JREXML
        assert_equal("jrexml", MARC::XMLReader.parser)
        reader = MARC::XMLReader.new('test/one.xml')
        assert_kind_of(REXML::Parsers::PullParser, reader.parser)
        MARC::XMLReader.parser="jrexml"
        assert_equal("jrexml", MARC::XMLReader.parser)
        reader = MARC::XMLReader.new('test/one.xml')
        assert_kind_of(REXML::Parsers::PullParser, reader.parser)
      rescue LoadError
        puts "\njrexml not available, skipping 'test_set_jrexml'.\n"
      end
    else
      puts "\nTest not being run from JRuby, skipping 'test_set_jrexml'.\n"
    end
  end

def test_set_jstax
  if defined? JRUBY_VERSION
    begin
      assert_equal("rexml", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(REXML::Parsers::PullParser, reader.parser)

      reader = MARC::XMLReader.new('test/one.xml', :parser=>MARC::XMLReader::USE_JSTAX)
      assert_kind_of(Java::ComSunOrgApacheXercesInternalImpl::XMLStreamReaderImpl, reader.parser)
      assert_equal("rexml", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml', :parser=>'jstax')
      assert_kind_of(Java::ComSunOrgApacheXercesInternalImpl::XMLStreamReaderImpl, reader.parser)
      assert_equal("rexml", MARC::XMLReader.parser)
      MARC::XMLReader.parser=MARC::XMLReader::USE_JSTAX
      assert_equal("jstax", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(Java::ComSunOrgApacheXercesInternalImpl::XMLStreamReaderImpl, reader.parser)
      MARC::XMLReader.parser="jstax"
      assert_equal("jstax", MARC::XMLReader.parser)
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(Java::ComSunOrgApacheXercesInternalImpl::XMLStreamReaderImpl, reader.parser)
    rescue java.lang.ClassNotFoundException
      puts "\njavax.xml.stream not available, skipping 'test_set_jstax'.\n"
    end
  else
    puts "\nTest not being run from JRuby, skipping 'test_set_jstax'.\n"
  end
end

  def test_set_rexml
    reader = MARC::XMLReader.new('test/one.xml', :parser=>MARC::XMLReader::USE_REXML)
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
    assert_equal("rexml", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml', :parser=>'rexml')
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
    assert_equal("rexml", MARC::XMLReader.parser)
    MARC::XMLReader.parser=MARC::XMLReader::USE_REXML
    assert_equal("rexml", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
    MARC::XMLReader.parser="rexml"
    assert_equal("rexml", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
  end

  def test_set_magic
    best = choose_best_available_parser
    magic_parser = best[:parser]
    puts "\nTesting 'test_set_magic' for parser: #{magic_parser}"
    reader = MARC::XMLReader.new('test/one.xml', :parser=>MARC::XMLReader::USE_BEST_AVAILABLE)
    assert_kind_of(magic_parser, reader.parser)
    assert_equal("rexml", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml', :parser=>'magic')
    assert_kind_of(magic_parser, reader.parser)
    assert_equal("rexml", MARC::XMLReader.parser)
    MARC::XMLReader.parser=MARC::XMLReader::USE_BEST_AVAILABLE
    assert_equal("magic", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(magic_parser, reader.parser)
    MARC::XMLReader.parser="magic"
    assert_equal("magic", MARC::XMLReader.parser)
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(magic_parser, reader.parser)
  end

  def test_parser_set_convenience_methods
    best = choose_best_available_parser
    parser = best[:parser]
    parser_name = best[:parser_name]
    assert_equal(parser_name, MARC::XMLReader.best_available)
    MARC::XMLReader.best_available!
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(parser, reader.parser)
    MARC::XMLReader.rexml!
    reader = MARC::XMLReader.new('test/one.xml')
    assert_kind_of(REXML::Parsers::PullParser, reader.parser)
    if parser_name == 'nokogiri'
      MARC::XMLReader.nokogiri!
      reader = MARC::XMLReader.new('test/one.xml')
      assert_kind_of(Nokogiri::XML::SAX::Parser, reader.parser)
    else
      puts "\nNokogiri not loaded, skipping convenience method test.\n"
    end
    if defined? JRUBY_VERSION
      begin
        require 'jrexml'
        MARC::XMLReader.jrexml!
        reader = MARC::XMLReader.new('test/one.xml')
        assert_kind_of(REXML::Parsers::PullParser, reader.parser)
      rescue LoadError
        puts "\njrexml not available, skipping convenience method test.\n"
      end
    else
      puts "\nTest not being run from JRuby, skipping jrexml convenience method test.\n"
    end
  end

  def teardown
    MARC::XMLReader.parser=MARC::XMLReader::USE_REXML
  end

  def choose_best_available_parser
    parser_name = nil
    parser = nil
    unless parser
      begin
        require 'nokogiri'
        parser_name = 'nokogiri'
        parser = Nokogiri::XML::SAX::Parser
      rescue LoadError
      end
    end
    unless parser
      if defined? JRUBY_VERSION
        require 'java'
        begin
          java.lang.Class.forName("javax.xml.stream.XMLInputFactory")
          parser_name = "jstax"
          parser = Java::ComSunOrgApacheXercesInternalImpl::XMLStreamReaderImpl
        rescue java.lang.ClassNotFoundException
        end
      end
    end
    unless parser
      if !defined? JRUBY_VERSION
        begin
          require 'xml'
          parser_name = 'libxml'
          parser = LibXML::XML::Reader
        rescue LoadError
        end
      else
        if defined? JRUBY_VERSION
          begin
            require 'jrexml'
            parser_name = 'jrexml'
            parser = REXML::Parsers::PullParser
          rescue LoadError
          end
        end
      end
      unless parser
        parser = REXML::Parsers::PullParser
        parser_name = 'rexml'
      end
    end
    return {:parser=>parser, :parser_name=>parser_name}
  end

end
