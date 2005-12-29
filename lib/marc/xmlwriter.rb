module MARC
  
  # A class for writing MARC records as MARC21.
  
  class XMLWriter
    
    MARC_NS = "http://www.loc.gov/MARC21/slim"
    MARC_XSD = "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"
    
    # the constructor which you must pass a file path
    # or an object that responds to a write message
    
    def initialize(file)
      if file.class == String
        @fh = File.new(file,"w")
      elsif file.respond_to?(file)
        @fh = file
      else
        throw "must pass in file name or handle"
      end
      
      @fh.write("<?xml version='1.0'?>")
      
      @fh.write("<marc:collection xmlns:marc='" + MARC_NS + "' " \
      + "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' " \
      + "xsi:schemaLocation='" + MARC_NS + " " + MARC_XSD + "'>")
    end
    
    
    # write a record to the file or handle
    
    def write(record)
      @fh.write(record.to_xml.to_s)
    end
    
    
    # close underlying filehandle
    
    def close
      @fh.write("</marc:collection>")
      @fh.close
    end
    
  end
  
end
