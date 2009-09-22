module MARC
  module NokogiriParserMethods
    def init
      @record = {:record=>nil,:field=>nil,:subfield=>nil}
      @current_element = nil
      @ns = "http://www.loc.gov/MARC21/slim"
      @parser = Nokogiri::XML::SAX::Parser.new(self)         
    end
    def attributes_to_hash(attributes)
      hash = {}
      attributes.each do | att |
        hash[att.localname] = att.value
      end
      hash
    end
    
    def start_element_namespace name, attributes = [], prefix = nil, uri = nil, ns = {}
      attributes = attributes_to_hash(attributes)
      if uri == @ns
        case name.downcase
        when 'record' then @record[:record] = MARC::Record.new
        when 'leader' then @current_element = :leader
        when 'controlfield'
          @current_element=:field
          @record[:field] = MARC::ControlField.new(attributes["tag"])
        when 'datafield'
          @record[:field] = MARC::DataField.new(attributes["tag"], attributes['ind1'], attributes['ind2'])
        when 'subfield'
          @current_element=:subfield
          @record[:subfield] = MARC::Subfield.new(attributes['code'])
        end
      end
    end

    def characters text
      case @current_element
      when :leader then @record[:record].leader = text
      when :field then @record[:field].value << text
      when :subfield then @record[:subfield].value << text
      end
    end

    def end_element_namespace name, prefix = nil, uri = nil
      @current_element = nil
      if uri == "http://www.loc.gov/MARC21/slim"
        case name.downcase
        when 'record' then yield_record
        when /(control|data)field/
          @record[:record] << @record[:field]
          @record[:field] = nil
          @current_element = nil if @current_element == :field          
        when 'subfield'
          @record[:field].append(@record[:subfield])
          @record[:subfield] = nil
          @current_element = nil if @current_element == :subfield
        end
      end
    end
    
    def yield_record
      @block.call(@record[:record])       
      @record[:record] = nil
    end
  end
end