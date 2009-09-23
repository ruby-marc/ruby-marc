module MARC

  # constants used in MARC21 reading/writing
  LEADER_LENGTH = 24
  DIRECTORY_ENTRY_LENGTH = 12
  SUBFIELD_INDICATOR = 0x1F.chr
  END_OF_FIELD = 0x1E.chr
  END_OF_RECORD = 0x1D.chr

  # constants used in XML reading/writing 
  MARC_NS = "http://www.loc.gov/MARC21/slim"
  MARC_XSD = "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd"

  # marc-hash
  MARCHASH_MAJOR_VERSION = 1
  MARCHASH_MINOR_VERSION = 0
  
end
