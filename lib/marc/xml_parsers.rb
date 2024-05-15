module MARC
  # Exception class to be thrown when an XML parser
  # encounters an unrecoverable error.
  class XMLParseError < StandardError
  end

  IND1 = "ind1".freeze
  IND2 = "ind2".freeze
  TAG = "tag".freeze
  CODE = "code".freeze

  # The MagicReader will try to use the best available XML Parser at the
  # time of initialization.
  # The order is currently:
  #   * Nokogiri
  #   * libxml-ruby (MRI only) ** DEPRECATED **
  #   * jstax (JRuby only) ** DEPRECATED **
  #   * rexml
  #
  # With the idea that other parsers could be added as their modules are
  # added.  Realistically, this list should be limited to stream-based
  # parsers.  The magic should be used selectively, however.  After all,
  # one project's definition of 'best' might not apply universally.  It
  # is arguable which is "best" on JRuby:  Nokogiri or jrexml.
  module MagicReader
    def self.extended(receiver)
      magic = MARC::XMLReader.best_available
      case magic
      when "nokogiri"
        receiver.extend(NokogiriReader)
      when "libxml"
        warn "libxml support will be removed in version 1.3. Prefer nokogiri instead"
        receiver.extend(LibXMLReader)
      when "jstax"
        warn "jstax support will be removed in version 1.3. Prefer nokogiri instead"
        receiver.extend(JRubySTAXReader)
      when "jrexml"
        warn "jrexml support is broken upstream; falling back to just rexml. Prefer nokogiri instead"
        receiver.extend(REXMLReader)
      else
        receiver.extend(REXMLReader)
      end
    end
  end

  module GenericPullParser
    # Submodules must include
    #  self.extended()
    #  init()
    #  attributes_to_hash(attributes)
    #  each

    class BuildingMARCHash
      attr_accessor :marc_hash, :stack

      def initialize(mh = empty_marc_hash, stack = [])
        @marc_hash = mh
        @stack = stack
      end

      def top
        @stack.last
      end

      def pop
        @stack.pop
      end

      def push(e)
        @stack.push(e)
      end

      def append(e)
        top.push e
      end

      def append_text(str)
        top.last << str
      end

      def empty_marc_hash
        { "type" => "marc-hash", "version" => [MARCHASH_MAJOR_VERSION, MARCHASH_MINOR_VERSION], "leader" => "", "fields" => [] }
      end
    end

    REC_TAG = "record".freeze
    LEAD_TAG = "leader".freeze
    CF_TAG = "controlfield".freeze
    DF_TAG = "datafield".freeze
    SF_TAG = "subfield".freeze

    def init
      @builder = BuildingMARCHash.new
      @ns = "http://www.loc.gov/MARC21/slim"
    end

    # Returns our MARC::Record object to the #each block.
    def yield_record
      record = @record_class.new_from_marchash(@builder.marc_hash)
      if record.valid?
        @block.call(record)
      elsif @error_handler
        @error_handler.call(self, record, @block)
      else
        raise MARC::RecordException, record
      end
    end

    def start_element_namespace name, attributes = [], prefix = nil, uri = nil, ns = {}
      attributes = attributes_to_hash(attributes)
      if (uri == @ns) || @ignore_namespace
        case name.downcase
        when SF_TAG
          @builder.push [attributes[CODE], ""]
          @current_element = :subfield
        when DF_TAG
          @builder.push [attributes[TAG], attributes[IND1], attributes[IND2], []]
          @current_element = :data_field
        when CF_TAG
          @builder.push [attributes[TAG], ""]
          @current_element = :control_field
        when LEAD_TAG then @current_element = :leader
        when REC_TAG
          @builder = BuildingMARCHash.new
        end
      end
    end

    def characters(text)
      case @current_element
      when :subfield
        @builder.append_text text
      when :control_field
        @builder.append_text text
      when :leader
        @builder.marc_hash["leader"] << text
      end
    end

    def end_element_namespace(name, prefix = nil, uri = nil)
      @current_element = nil
      if (uri == @ns) || @ignore_namespace
        case name.downcase
        when SF_TAG
          sf = @builder.pop
          @builder.top.last.push sf
        when DF_TAG, CF_TAG
          @builder.marc_hash["fields"].push @builder.pop
        when REC_TAG then yield_record
        # when LEAD_TAG
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

    def self.extended(receiver)
      require "nokogiri"
      receiver.init
    end

    # Sets our instance variables for SAX parsing in Nokogiri and parser
    def init
      super
      @parser = Nokogiri::XML::SAX::Parser.new(self)
    end

    # Loop through the MARC records in the XML document
    def each(&block)
      if block
        @block = block
        @parser.parse(@handle)
      else
        enum_for(:each)
      end
    end

    def error(evt)
      raise(XMLParseError, "XML parsing error: #{evt}")
    end

    SAX_METHODS = [:xmldecl, :start_document, :end_document, :start_element,
                   :end_element, :comment, :warning, :error, :cdata_block, :processing_instruction]

    def method_missing(method_name, *args)
      unless SAX_METHODS.include?(method_name)
        raise NoMethodError.new("undefined method '#{method_name} for #{self}", "no_meth")
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      SAX_METHODS.include?(method_name) || super
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

  # The REXMLReader is the 'default' parser, since we can at least be
  # assured that REXML is probably there.  It uses REXML's PullParser
  # to handle larger document sizes without consuming insane amounts of
  # memory, but it's still REXML (read: slow), so it's a good idea to
  # use an alternative parser if available.  If you don't know the best
  # parser available, you can use the MagicReader or set:
  #
  # MARC::XMLReader.parser=MARC::XMLReader::USE_BEST_AVAILABLE
  #
  # or
  #
  # MARC::XMLReader.parser="magic"
  #
  # or
  #
  # reader = MARC::XMLReader.new(fh, :parser=>"magic")
  # (or the constant)
  #
  # which will cascade down to REXML if nothing better is found.
  #
  module REXMLReader
    def self.extended(receiver)
      require "rexml/document"
      require "rexml/parsers/pullparser"
      receiver.init
    end

    # Sets our parser
    def init
      @parser = REXML::Parsers::PullParser.new(@handle)
    end

    # Loop through the MARC records in the XML document
    def each
      if block_given?
        while @parser.has_next?
          event = @parser.pull
          # if it's the start of a record element
          if event.start_element? && (strip_ns(event[0]) == "record")
            yield build_record
          end
        end
      else
        enum_for(:each)
      end
    end

    private

    def strip_ns(str)
      str.sub(/^.*:/, "")
    end

    # will accept parse events until a record has been built up
    #
    def build_record
      record = MARC::Record.new
      data_field = nil
      control_field = nil
      subfield = nil
      text = ""
      attrs = nil
      if Module.constants.index("Nokogiri") && @parser.is_a?(Nokogiri::XML::Reader)
        datafield = nil
        cursor = nil
        open_elements = []
        @parser.each do |node|
          if node.value? && cursor
            if cursor.is_a?(Symbol) && (cursor == :leader)
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
            control_field = MARC::ControlField.new(node.attribute("tag"))
            record << control_field
            cursor = control_field
          when "datafield"
            record << datafield if datafield
            datafield = nil
            data_field = MARC::DataField.new(node.attribute("tag"), node.attribute(IND1), node.attribute(IND2))
            datafield = data_field
          when "subfield"
            raise "No datafield to add to" unless datafield
            subfield = MARC::Subfield.new(node.attribute(CODE))
            datafield.append(subfield)
            cursor = subfield
          when "record"
            record << datafield if datafield
            return record
          end
        end

      else
        while @parser.has_next?
          event = @parser.pull

          if event.text?
            text += REXML::Text.unnormalize(event[0])
            next
          end

          if event.start_element?
            text = ""
            attrs = event[1]
            case strip_ns(event[0])
            when "controlfield"
              text = ""
              control_field = MARC::ControlField.new(attrs[TAG])
            when "datafield"
              text = ""
              data_field = MARC::DataField.new(attrs[TAG], attrs[IND1],
                                               attrs[IND2])
            when "subfield"
              text = ""
              subfield = MARC::Subfield.new(attrs[CODE])
            end
          end

          if event.end_element?
            case strip_ns(event[0])
            when "leader"
              record.leader = text
            when "record"
              return record
            when "controlfield"
              control_field.value = text
              record.append(control_field)
            when "datafield"
              record.append(data_field)
            when "subfield"
              subfield.value = text
              data_field.append(subfield)
            end
          end
        end
      end
    end
  end

  unless defined? JRUBY_VERSION
    module LibXMLReader
      def self.extended(receiver)
        require "xml"
        receiver.init
      end

      def init
        @ns = "http://www.loc.gov/MARC21/slim"
        @parser = XML::Reader.io(@handle)
      end

      def each
        if block_given?
          while @parser.read
            if @parser.local_name == "record" && @parser.namespace_uri == @ns
              yield build_record
            end
          end # while
        else
          enum_for(:each)
        end
      end

      # each

      def build_record
        r = MARC::Record.new
        until (@parser.local_name == "record") && (@parser.node_type == XML::Reader::TYPE_END_ELEMENT)
          @parser.read
          next if @parser.node_type == XML::Reader::TYPE_END_ELEMENT
          case @parser.local_name
          when "leader"
            @parser.read
            r.leader = @parser.value
          when "controlfield"
            tag = @parser[TAG]
            @parser.read
            r << MARC::ControlField.new(tag, @parser.value)
          when "datafield"
            data = MARC::DataField.new(@parser[TAG], @parser[IND1], @parser[IND2])
            while @parser.read && !((@parser.local_name == "datafield") && (@parser.node_type == XML::Reader::TYPE_END_ELEMENT))
              next if @parser.node_type == XML::Reader::TYPE_END_ELEMENT
              case @parser.local_name
              when "subfield"
                code = @parser[CODE]
                @parser.read
                data.append(MARC::Subfield.new(code, @parser.value))
              end
            end
            r << data

          end # case
        end # until
        r
      end
    end
  end

  # The JrubySTAXReader uses native java calls to parse the incoming stream
  # of marc-xml. It includes most of the work from GenericPullParser

  if defined? JRUBY_VERSION
    # *DEPRECATED*: JRubySTAXReader is deprecated and will be removed in a
    # future version of ruby-marc. Please use NokogiriReader
    # instead.
    module JRubySTAXReader
      include GenericPullParser

      def self.extended(receiver)
        require "java" # may only be neccesary in jruby 1.6
        receiver.init
      end

      def init
        warn "JRubySTAXReader is deprecated and will be removed in a future version of ruby-marc."

        super
        @factory = javax.xml.stream.XMLInputFactory.newInstance
        @parser = @factory.createXMLStreamReader(@handle.to_inputstream)
      end

      # Loop through the MARC records in the XML document
      def each(&block)
        if block
          @block = block
          parser_dispatch
        else
          enum_for(:each)
        end
      end

      def parser_dispatch
        while (event = @parser.next) && (event != javax.xml.stream.XMLStreamConstants::END_DOCUMENT)
          case event
          when javax.xml.stream.XMLStreamConstants::START_ELEMENT
            start_element_namespace(@parser.getLocalName, [], nil, @parser.getNamespaceURI, nil)
          when javax.xml.stream.XMLStreamConstants::END_ELEMENT
            end_element_namespace(@parser.getLocalName, @parser.getPrefix, @parser.getNamespaceURI)
          when javax.xml.stream.XMLStreamConstants::CHARACTERS
            characters(@parser.getText)
          end
        end
      end

      def attributes_to_hash(attributes)
        hash = {}
        @parser.getAttributeCount.times do |i|
          hash[@parser.getAttributeName(i).getLocalPart] = @parser.getAttributeValue(i)
        end
        hash
      end
    end # end of module
  end # end of if jruby
end
