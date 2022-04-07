require File.dirname(__FILE__) + '/xml_parsers'
require 'nokogiri'

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
  # You can also pass in an error_handler option that will be called if
  # there are any validation errors found when parsing a record.
  #
  #  reader = MARC::XMLReader.new(fh, error_handler: ->(reader, record, block) { ... })
  #
  # By default, a MARC::RecordException is raised halting all future parsing.
  class XMLReader
    include Enumerable
    include NokogiriReader

    attr_reader :error_handler

    def initialize(file, options = {})
      if file.is_a?(String)
        handle = File.new(file)
      elsif file.respond_to?("read", 5)
        handle = file
      else raise ArgumentError, "must pass in path or File"
      end
      @handle = handle
      @error_handler = options[:error_handler]
      self.init
    end

    # Returns the currently set parser type
    def self.parser
      return :nokogiri
    end

    # Returns an array of all the parsers available
    def self.parsers
      [:nokogiri]
    end

    # Sets the class parser
    def self.parser=(p)
      # null action
    end

    # Returns the value of the best available parser
    def self.best_available
      :nokogiri
    end

    # Sets the best available parser as the default
    def self.best_available!
      :nokogiri
    end

    # Sets Nokogiri as the default parser
    def self.nokogiri!
      :nokogiri
    end

    # Sets jrexml as the default parser
    def self.jrexml!
      :nokogiri
    end

    # Sets REXML as the default parser
    def self.rexml!
      :nokogiri
    end

    protected

    def self.choose_parser(p)
      :nokogiri
    end
  end
end
