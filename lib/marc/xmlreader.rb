module MARC
  
  class XMLReader
    include Enumerable
    USE_BEST_AVAILABLE = 'magic'
    USE_REXML = 'rexml'
    USE_NOKOGIRI = 'nokogiri'
    USE_JREXML = 'jrexml'
    @@parser = USE_REXML
    attr_reader :parser
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
    #   MARC::XMLReader.parser=MARC::XMLReader::USE_BEST_AVAILABLE
    #
    # Like the instance initialization override it will accept either the 
    # constant name or value.
    #
 
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
        parser = self.class.choose_parser(options[:parser])
      else
        parser = @@parser
      end
      #if parser=='rexml' or !(Kernel.const_defined?(:Nokogiri) || Module.constants.index('Nokogiri'))
      #  @parser = REXML::Parsers::PullParser.new(handle)
      #else
      #  extend NokogiriParserMethods
      #  self.init
      #  @handle = handle     
      #end
      case parser
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
    
    protected
    
    def self.choose_parser(p)
      if p.match(/^[A-Z]/) && self.const_defined?(p)
        parser = self.const_get(p)
      else
        match = false
        self.constants.each do | const |
          next unless const.match("^USE_")
          if self.const_get(const) == p
            match = true
            parser == p
            break
          end
        end
        raise ArgumentError.new("Parser '#{p}' not defined") unless match
      end
      parser    
    end
  end
end
