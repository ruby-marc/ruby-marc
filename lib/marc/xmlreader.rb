require File.dirname(__FILE__) + '/xml_parsers'
module MARC

  # the constructor which you can pass either a filename:
  #
  #   reader = MARC::XMLReader.new('/Users/edsu/marc.xml')
  #
  # or a File object, 
  #
  #   reader = Marc::XMLReader.new(File.new('/Users/edsu/marc.xml'))
  #
  # or really any object that responds to read(n)
  # 
  #   reader = MARC::XMLReader.new(StringIO.new(xml))
  #
  # By default, XMLReader uses REXML's pull parser, but you can swap
  # that out with Nokogiri or jrexml (or let the system choose the
  # 'best' one).  The :parser can either be one of the defined constants
  # or the constant's value.
  #
  #   reader = MARC::XMLReader.new(fh, :parser=>'magic') 
  #
  # It is also possible to set the default parser at the class level so
  # all subsequent instances will use it instead:
  #
  #   MARC::XMLReader.best_available
  #   "nokogiri" # returns parser name, but doesn't set it.
  #
  # Use:
  #   MARC::XMLReader.best_available!
  # 
  # or
  #   MARC::XMLReader.nokogiri!
  # 
  class XMLReader
    include Enumerable
    USE_BEST_AVAILABLE = 'magic'
    USE_REXML = 'rexml'
    USE_NOKOGIRI = 'nokogiri'
    USE_JREXML = 'jrexml'
    @@parser = USE_REXML
    attr_reader :parser
 
    def initialize(file, options = {})
      if file.is_a?(String)
        handle = File.new(file)
      elsif file.respond_to?("read", 5)
        handle = file
      else
        throw "must pass in path or File"
      end
      @handle = handle

      if options[:parser]
        parser = self.class.choose_parser(options[:parser].to_s)
      else
        parser = @@parser
      end
      case parser
      when 'magic' then extend MagicReader
      when 'rexml' then extend REXMLReader
      when 'jrexml' then extend JREXMLReader
      when 'nokogiri' then extend NokogiriReader        
      end
    end

    # Returns the currently set parser type
    def self.parser
      return @@parser
    end
    
    # Returns an array of all the parsers available
    def self.parsers
      p = []
      self.constants.each do | const |
        next unless const.match("^USE_")
        p << const
      end      
      return p
    end
    
    # Sets the class parser
    def self.parser=(p)
      @@parser = choose_parser(p)
    end

    # Returns the value of the best available parser
    def self.best_available
      parser = nil
      begin
        require 'nokogiri'
        parser = USE_NOKOGIRI
      rescue LoadError
        if RUBY_PLATFORM =~ /java/
          begin
            require 'jrexml'
            parser = USE_JREXML
          rescue LoadError
            parser = USE_REXML
          end
        else
          parser = USE_REXML
        end
        parser
      end            
    end
    
    # Sets the best available parser as the default
    def self.best_available!
      @@parser = self.best_available
    end
    
    # Sets Nokogiri as the default parser
    def self.nokogiri!
      @@parser = USE_NOKOGIRI
    end
    
    # Sets jrexml as the default parser
    def self.jrexml!
      @@parser = USE_JREXML
    end
    
    # Sets REXML as the default parser
    def self.rexml!
      @@parser = USE_REXML
    end
        
    protected
    
    def self.choose_parser(p)
      match = false
      self.constants.each do | const |
        next unless const.to_s.match("^USE_")
        if self.const_get(const) == p
          match = true
          return p
        end
      end
      raise ArgumentError.new("Parser '#{p}' not defined") unless match
    end
  end
end
