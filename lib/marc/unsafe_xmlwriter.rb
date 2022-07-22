require "marc"

module MARC
  # UnsafeXMLWriter bypasses real xml handlers like REXML or Nokogiri and just concatenates strings
  # to produce the XML document. This has no guarantees of validity if the MARC record you're encoding
  # isn't valid and won't do things like entity expansion, but it does escape using ruby's
  # String#encode(xml: :text) and it's much, much faster -- 4-5 times faster than using Nokogiri,
  # and 15-20 times faster than the REXML version.
  class UnsafeXMLWriter < MARC::XMLWriter
    XML_HEADER = '<?xml version="1.0" encoding="UTF-8"?>'

    # Write the record to the target
    # @param [MARC::Record] record
    def write(record)
      @fh.write(self.class.encode(record))
    end

    class << self
      # Produce an XML string with a single document in a collection
      # @param [MARC::Record] record
      # @param [Boolean] use_namespace Whether to namespace the resulting XML
      def single_record_document(record, use_namespace: true)
        xml = XML_HEADER.dup
        xml << MARC::XMLWriter::COLLECTION_TAG
        xml << encode(record)
        xml << "</collection>"
        xml
      end

      # Take a record and turn it into a valid MARC-XML string. Note that
      # this is an XML _snippet_, without an XML header or <collection>
      # enclosure.
      # @param [MARC::Record] record The record to encode to XML
      # @return [String] The XML snippet of the record in MARC-XML
      def encode(record)
        xml = "<record>"

        # MARCXML only allows alphanumerics or spaces in the leader
        lead = fix_leader(record.leader)

        xml << "<leader>" << lead.encode(xml: :text) << "</leader>"
        record.each do |f|
          if f.instance_of?(MARC::DataField)
            xml << open_datafield(f.tag, f.indicator1, f.indicator2)
            f.each do |sf|
              xml << open_subfield(sf.code) << sf.value.encode(xml: :text) << "</subfield>"
            end
            xml << "</datafield>"
          elsif f.instance_of?(MARC::ControlField)
            xml << open_controlfield(f.tag) << f.value.encode(xml: :text) << "</controlfield>"
          end
        end
        xml << "</record>"
        xml.force_encoding("utf-8")
      end

      def open_datafield(tag, ind1, ind2)
        "<datafield tag=\"#{tag}\" ind1=\"#{ind1}\" ind2=\"#{ind2}\">"
      end

      def open_subfield(code)
        "<subfield code=\"#{code}\">"
      end

      def open_controlfield(tag)
        "<controlfield tag=\"#{tag}\">"
      end
    end
  end
end
