require 'rexml/document'

module MARC
  
  # A class for writing MARC records as MARC21.
  
  class XMLWriter
    
    # the constructor which you must pass a file path
    # or an object that responds to a write message
    
    def initialize(file)
      if file.class == String
        @fh = File.new(file,"w")
      elsif file.respond_to?('write')
        @fh = file
      else
        throw "must pass in file name or handle"
      end
      
      @fh.write("<?xml version='1.0'?>")
      
      @fh.write("<marc:collection xmlns:marc='" + MARC_NS + "' " +
        "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' " +
        "xsi:schemaLocation='" + MARC_NS + " " + MARC_XSD + "'>")
    end
    
    
    # write a record to the file or handle
    
    def write(record)
      @fh.write(MARC::XMLWriter.encode(record).to_s)
    end
    
    
    # close underlying filehandle
    
    def close
      @fh.write("</marc:collection>")
      @fh.close
    end

    
    # a static method that accepts a MARC::Record object
    # and returns a REXML::Document for the XML serialization

    def self.encode(record)
      root = "<marc:record xmlns:marc='" + MARC_NS + "'/>"
      doc = REXML::Document.new root

      # MARCXML is particular about this; ILSes aren't
      record.leader[20..24] = "4500"
      
      leader = REXML::Element.new "marc:leader"
      leader.add_text record.leader
      doc.root.add_element leader
      
      for field in record.fields
        if field.class == MARC::Field 
          datafield_elem = REXML::Element.new "marc:datafield"
          datafield_elem.add_attributes({
            "tag"=>field.tag,
            "ind1"=>field.indicator1,
            "ind2"=>field.indicator2
          })

          for subfield in field.subfields
            subfield_element = REXML::Element.new "marc:subfield"
            subfield_element.add_attribute("code", subfield.code)
            subfield_element.add_text subfield.value
            datafield_elem.add_element subfield_element
          end
          
          doc.root.add_element datafield_elem
        elsif field.class == MARC::Control
          control_element = REXML::Element.new "marc:controlfield"
          control_element.add_attribute("tag", field.tag)
          control_element.add_text field.value
          doc.root.add_element control_element
        end
      end
      
      # return xml
      return doc
    end
  end
end
