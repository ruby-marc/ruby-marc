require File.dirname(__FILE__) + '/xml_parsers'
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

    # will accept parse events until a record has been built up
    #
    def build_record
      record = MARC::Record.new
      data_field = nil
      control_field = nil
      subfield = nil
      text = '' 
      attrs = nil

      while @parser.has_next?
        event = @parser.pull

        if event.text?
          text += REXML::Text::unnormalize(event[0])
          next
        end

        if event.start_element?
          text = ''
          attrs = event[1]
          case strip_ns(event[0])
          when 'controlfield'
            text = ''
            control_field = MARC::ControlField.new(attrs['tag'])
          when 'datafield'
            text = ''
            data_field = MARC::DataField.new(attrs['tag'], attrs['ind1'], 
              attrs['ind2'])
          when 'subfield'
            text = ''
            subfield = MARC::Subfield.new(attrs['code'])
          end
        end

        if event.end_element?
          case strip_ns(event[0])
          when 'leader'
            record.leader = text
          when 'record'
            return record
          when 'controlfield'
            control_field.value = text
            record.append(control_field)
          when 'datafield'
            record.append(data_field)
          when 'subfield'
            subfield.value = text
            data_field.append(subfield)
          end
        end
      end
      raise ArgumentError.new("Parser '#{p}' not defined") unless match
    end
  end
end
