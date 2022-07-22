require File.dirname(__FILE__) + "/xml_parsers"
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
  # By default, all XML parsers except REXML require the MARC namespace
  # (http://www.loc.gov/MARC21/slim) to be included. Adding the option
  # `ignore_namespace` to the call to `new` with a true value
  # will allow parsing to proceed,  e.g.,
  #
  #     reader = MARC::XMLReader.new(filename, parser: :nokogiri, ignore_namespace: true)
  #
  # You can also pass in an error_handler option that will be called if
  # there are any validation errors found when parsing a record.
  #
  #  reader = MARC::XMLReader.new(fh, error_handler: ->(reader, record, block) { ... })
  #
  # By default, a MARC::RecordException is raised halting all future parsing.
  class XMLReader
    include Enumerable
    USE_BEST_AVAILABLE = "magic"
    USE_REXML = "rexml"
    USE_NOKOGIRI = "nokogiri"
    USE_JREXML = "jrexml"
    USE_JSTAX = "jstax"
    USE_LIBXML = "libxml"
    @@parser = USE_REXML
    attr_reader :parser, :error_handler

    def initialize(file, options = {})
      if file.is_a?(String)
        handle = File.new(file)
      elsif file.respond_to?(:read, 5)
        handle = file
      else
        raise ArgumentError, "must pass in path or File"
      end
      @handle = handle

      if options[:ignore_namespace]
        @ignore_namespace = options[:ignore_namespace]
      end

      parser = if options[:parser]
        self.class.choose_parser(options[:parser].to_s)
      else
        @@parser
      end

      case parser
      when "magic" then extend MagicReader
      when "rexml" then extend REXMLReader
      when "jrexml"
        raise ArgumentError, "jrexml only available under jruby" unless defined? JRUBY_VERSION
        extend JREXMLReader
      when "nokogiri" then extend NokogiriReader
      when "jstax"
        raise ArgumentError, "jstax only available under jruby" unless defined? JRUBY_VERSION
        extend JRubySTAXReader
      when "libxml" then extend LibXMLReader
                         raise ArgumentError, "libxml not available under jruby" if defined? JRUBY_VERSION
      end

      @error_handler = options[:error_handler]
    end

    class << self
      # Returns the currently set parser type
      def parser
        @@parser
      end

      # Returns an array of all the parsers available
      def parsers
        p = []
        constants.each do |const|
          next unless const.match?("^USE_")
          p << const
        end
        p
      end

      # Sets the class parser
      def parser=(p)
        @@parser = choose_parser(p)
      end

      # Returns the value of the best available parser
      def best_available
        parser = nil
        if defined? JRUBY_VERSION
          unless parser
            begin
              require "nokogiri"
              parser = USE_NOKOGIRI
            rescue LoadError
            end
          end
          unless parser
            begin
              # try to find the class, so we throw an error if not found
              java.lang.Class.forName("javax.xml.stream.XMLInputFactory")
              parser = USE_JSTAX
            rescue java.lang.ClassNotFoundException
            end
          end
          unless parser
            begin
              require "jrexml"
              parser = USE_JREXML
            rescue LoadError
            end
          end
        else
          begin
            require "nokogiri"
            parser = USE_NOKOGIRI
          rescue LoadError
          end
          unless defined? JRUBY_VERSION
            unless parser
              begin
                require "xml"
                parser = USE_LIBXML
              rescue LoadError
              end
            end
          end
        end
        parser ||= USE_REXML
        parser
      end

      # Sets the best available parser as the default
      def best_available!
        @@parser = best_available
      end

      # Sets Nokogiri as the default parser
      def nokogiri!
        @@parser = USE_NOKOGIRI
      end

      # Sets jrexml as the default parser
      def jrexml!
        @@parser = USE_JREXML
      end

      # Sets REXML as the default parser
      def rexml!
        @@parser = USE_REXML
      end

      def choose_parser(p)
        match = false
        constants.each do |const|
          next unless const.to_s.match?("^USE_")
          if const_get(const) == p
            match = true
            return p
          end
        end
        raise ArgumentError.new("Parser '#{p}' not defined") unless match
      end
    end
  end
end
