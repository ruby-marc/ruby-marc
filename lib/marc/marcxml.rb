require "rexml/document"

include REXML

module MARC
  
  # Provides methods for serializing and deserializing MARC::Record
  # objects as MARCXML transmission format.
  
  class MARCXML
    
    MARC_NS = "http://www.loc.gov/MARC21/slim"
    MARC_XSD = "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    
    # Returns the MARCXML serialization for a MARC::Record
    def encode(record)
      root = "<marc:record xmlns:marc='" + MARC_NS + "'/>"
      doc = Document.new root

      # MARCXML is particular about this; ILSes aren't
      record.leader[20..24] = "4500"
      
      leader = Element.new "marc:leader"
      leader.add_text record.leader
      doc.root.add_element leader
      
      for field in record.fields
        if field.class == MARC::Field 
          dfElem = Element.new "marc:datafield"
          dfElem.add_attributes({
            "tag"=>field.tag,
            "ind1"=>field.indicator1,
            "ind2"=>field.indicator2
          })

          for subfield in field.subfields
            sfElem = Element.new "marc:subfield"
            sfElem.add_attribute("code", subfield.code)
            sfElem.add_text subfield.value
            dfElem.add_element sfElem
          end
          
          doc.root.add_element dfElem
        elsif field.class == MARC::Control
          cfElem = Element.new "marc:controlfield"
          cfElem.add_attribute("tag", field.tag)
          cfElem.add_text field.value
          doc.root.add_element cfElem
        end
      end
      
      # return xml
      return doc
    end
  end
  
end
