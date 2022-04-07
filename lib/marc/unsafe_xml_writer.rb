
require 'marc/xmlwriter'

module MARC
  class UnsafeXMLWriter < MARC::XMLWriter

    @xml_header = '<?xml version="1.0" encoding="UTF-8"?>'
    @open_record = '<record>' # or "<marc:record">
    @open_record_namespace = '<marc:record>'

    @open_leader = '<leader>'

    def initialize(file, opts = {})
      super
    end

    def write(record)
      @fh.write(self.class.encode(record), "\n")
    end

    class << self
      def single_record_document(r, opts = {})
        xml = @xml_header.dup
        xml << '<collection>'
        xml << encode(r, opts)
        xml << '</collection>'
        xml
      end

      def open_datafield(tag, ind1, ind2)
        # return "\n  <datafield tag=\"#{tag}\" ind1=\"#{ind1}\" ind2=\"#{ind2}\">"
        "<datafield tag=\"#{tag}\" ind1=\"#{ind1}\" ind2=\"#{ind2}\">"
      end

      def open_subfield(code)
        # return "\n    <subfield code=\"#{code}\">"
        "<subfield code=\"#{code}\">"
      end

      def open_controlfield(tag)
        # return "\n<controlfield tag=\"#{tag}\">"
        "<controlfield tag=\"#{tag}\">"
      end

      def encode(r, opts = {})
        xml = (opts[:include_namespace] ? @open_record_namespace.dup : @open_record.dup)

        # MARCXML only allows alphanumerics or spaces in the leader
        lead = r.leader.gsub(/[^\w|^\s]/, 'Z').encode(xml: :text)

        # MARCXML is particular about last four characters; ILSes aren't
        lead.ljust(23, ' ')[20..23] = '4500'

        # MARCXML doesn't like a space here so we need a filler character: Z
        lead[6..6] = 'Z' if lead[6..6] == ' '

        xml << @open_leader << lead.encode(xml: :text) << '</leader>'
        r.each do |f|
          if f.class == MARC::DataField
            xml << open_datafield(f.tag, f.indicator1, f.indicator2)
            f.each do |sf|
              xml << open_subfield(sf.code) << sf.value.encode(xml: :text) << '</subfield>'
            end
            xml << '</datafield>'
          elsif f.class == MARC::ControlField
            xml << open_controlfield(f.tag) << f.value.encode(xml: :text) << '</controlfield>'
          end
        end
        xml << '</record>'
        xml.force_encoding('utf-8')
      end

      alias_method :encode_to_xml_string, :encode
    end
  end
end