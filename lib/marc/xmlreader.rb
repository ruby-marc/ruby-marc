begin
  require 'rubygems'
  require 'nokogiri'
  require File.dirname(__FILE__) + '/nokogiri_methods'
  PARENT_CLASS = Nokogiri::XML::SAX::Document
rescue LoadError
  PARENT_CLASS = Object
end
require 'rexml/document'
require 'rexml/parsers/pullparser'

module MARC
  
  class XMLReader < PARENT_CLASS
    include Enumerable

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
 
    def initialize(file, parser=nil)
      if file.is_a?(String)
        handle = File.new(file)
      elsif file.respond_to?("read", 5)
        handle = file
      else
        throw "must pass in path or File"
      end
      if parser=='rexml' or !Module.constants.index('Nokogiri')
        @parser = REXML::Parsers::PullParser.new(handle)
      else
        extend NokogiriParserMethods
        self.init
        @handle = handle     
      end
    end

    def each(&block)
      if self.respond_to?(:yield_record)
        @block = block
        @parser.parse(@handle)         
      else
        while @parser.has_next?
          event = @parser.pull
          # if it's the start of a record element 
          if event.start_element? and strip_ns(event[0]) == 'record'
            yield build_record
          end
        end
      end
    end

    private

    def strip_ns(str)
      return str.sub(/^.*:/, '')
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
      if Module.constants.index('Nokogiri') and @parser.is_a?(Nokogiri::XML::Reader)
        datafield = nil
        cursor = nil
        open_elements = []
        @parser.each do | node |
          if node.value? && cursor
            if cursor.is_a?(Symbol) and cursor == :leader
              record.leader = node.value
            else
              cursor.value = node.value
            end
            cursor = nil
          end
          next unless node.namespace_uri == @ns
          if open_elements.index(node.local_name.downcase)
            open_elements.delete(node.local_name.downcase)
            next
          else
            open_elements << node.local_name.downcase
          end
          case node.local_name.downcase
          when "leader"
            cursor = :leader
          when "controlfield"
            record << datafield if datafield
            datafield = nil
            control_field = MARC::ControlField.new(node.attribute('tag'))
            record << control_field
            cursor = control_field
          when "datafield"  
            record << datafield if datafield
            datafield = nil
            data_field = MARC::DataField.new(node.attribute('tag'), node.attribute('ind1'), node.attribute('ind2'))
            datafield = data_field
          when "subfield"
            raise "No datafield to add to" unless datafield
            subfield = MARC::Subfield.new(node.attribute('code'))
            datafield.append(subfield)
            cursor = subfield
          when "record"
            record << datafield if datafield
            return record
          end          
          #puts node.name
        end
        
      else
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
      end
    end

  end
end
