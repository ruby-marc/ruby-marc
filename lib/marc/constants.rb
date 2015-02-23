module MARC

  # constants used in MARC21 reading/writing
  LEADER_LENGTH = 24
  DIRECTORY_ENTRY_LENGTH = 12
  SUBFIELD_INDICATOR = 0x1F.chr.freeze
  END_OF_FIELD = 0x1E.chr.freeze
  END_OF_RECORD = 0x1D.chr.freeze

  # constants used in XML reading/writing 
  MARC_NS = "http://www.loc.gov/MARC21/slim".freeze
  MARC_XSD = "http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd".freeze

  # marc-hash
  MARCHASH_MAJOR_VERSION = 1
  MARCHASH_MINOR_VERSION = 0
  
end
