module MARC
  # Exception class to be thrown when an XML parser
  # encounters an unrecoverable error.
  class XMLParseError < StandardError; end

  # Deprecated; always uses nokogiri
  module MagicReader
    def self.extended(receiver)
      receiver.extend(NokogiriReader)
    end
  end

  module GenericPullParser
    # Submodules must include
    #  self.extended()
    #  init()
    #  attributes_to_hash(attributes)
    #  each

    def init
      @record = {:record => nil, :leader => '', :field => nil, :subfield => nil}
      @current_element = nil
      @ns = "http://www.loc.gov/MARC21/slim"
    end

    # Returns our MARC::Record object to the #each block.
    def yield_record
      if @record[:record].valid?
        @block.call(@record[:record])
      elsif @error_handler
        @error_handler.call(self, @record[:record], @block)
      else raise MARC::RecordException, @record[:record]
      end
    ensure @record[:record] = nil
    end

    def start_element_namespace(name, attributes = [], prefix = nil, uri = nil, ns = {})
      attributes = attributes_to_hash(attributes)
      if uri == @ns
        case name.downcase
          when 'subfield'
            @current_element = :subfield
            @record[:subfield] = MARC::Subfield.new(attributes['code'])
          when 'controlfield'
            @current_element = :field
            @record[:field] = MARC::ControlField.new(attributes["tag"])
          when 'datafield'
            @record[:field] = MARC::DataField.new(attributes["tag"], attributes['ind1'], attributes['ind2'])
          when 'record' then @record[:record] = MARC::Record.new
          when 'leader' then @current_element = :leader
        end
      end
    end

    def characters text
      case @current_element
        when :leader then @record[:leader] << text
        when :field then @record[:field].value << text
        when :subfield then @record[:subfield].value << text
      end
    end

    def end_element_namespace(name, prefix = nil, uri = nil)
      @current_element = nil
      if uri == @ns
        case name.downcase
          when 'subfield'
            @record[:field].append(@record[:subfield])
            @record[:subfield] = nil
            @current_element = nil if @current_element == :subfield
          when 'controlfield', 'datafield'
            @record[:record] << @record[:field]
            @record[:field] = nil
            @current_element = nil if @current_element == :field
          when 'record' then yield_record
          when 'leader'
            @record[:record].leader = @record[:leader]
            @record[:leader] = ''
            @current_element = nil if @current_element == :leader
        end
      end
    end

  end

  # NokogiriReader uses the Nokogiri SAX Parser to quickly read
  # a MARCXML document.  Because dynamically subclassing MARC::XMLReader
  # is a little ugly, we need to recreate all of the SAX event methods
  # from Nokogiri::XML::SAX::Document here rather than subclassing.
  module NokogiriReader
    include GenericPullParser

    # Sets our instance variables for SAX parsing in Nokogiri and parser
    def init
      super
      @parser = Nokogiri::XML::SAX::Parser.new(self)
    end

    # Loop through the MARC records in the XML document
    def each(&block)
      unless block_given?
        return self.enum_for(:each)
      else @block = block
      @parser.parse(@handle)
      end
    end

    def error(evt)
      raise(XMLParseError, "XML parsing error: #{evt}")
    end

    def method_missing(methName, *args)
      sax_methods = [:xmldecl, :start_document, :end_document, :start_element, :end_element, :comment, :warning, :error, :cdata_block, :processing_instruction]
      unless sax_methods.index(methName)
        raise NoMethodError.new("undefined method '#{methName} for #{self}", 'no_meth')
      end
    end

    private

    def attributes_to_hash(attributes)
      hash = {}
      attributes.each do |att|
        hash[att.localname] = att.value
      end
      hash
    end
  end
end
