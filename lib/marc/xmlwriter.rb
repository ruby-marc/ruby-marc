require 'nokogiri'
require 'marc/rexml_writer'

module MARC

  # A class for writing MARC records as MARCXML.
  # BIG CAVEAT! XMLWriter will *not* convert your MARC8 to UTF8

  class XMLWriter

    SINGLE_CHAR_RE = Regexp.new('[\da-z ]{1}').freeze
    SUBFIELD_CHAR_RE = Regexp.new('[\dA-Za-z!"#$%&\'()*+,-./:;<=>?{}_^`~\[\]\\\]{1}').freeze
    CTRLFIELD_TAG_RE = Regexp.new('00[1-9A-Za-z]{1}').freeze

    # Need a way to set the nokogiri doc object from outside for
    # use in new_encoder. Usually set in the initializer for
    # a "normal" writer.
    attr_writer :doc

    # the constructor which you must pass a file path
    # or an object that responds to a write message
    # the second argument is a hash of options, currently
    # only supporting one option, stylesheet
    # 
    # writer = XMLWriter.new 'marc.xml', :stylesheet => 'style.xsl'
    # writer.write record
    def initialize(file, opts = {})
      if file.class == String
        @fh = File.new(file, "w")
      elsif file.respond_to?('write')
        @fh = file
      else raise ArgumentError, "must pass in file name or handle"
      end

      write_header(opts[:stylesheet])
      @doc = Nokogiri::XML::Document.new
    end

    # Alternate constructor for when we just need a raw instance to run
    # encode_to_xml_string on a single record, since we need a @doc.
    def self.new_encoder
      obj = self.allocate
      obj.doc = Nokogiri::XML::Document.new
      obj
    end

    def write_header(add_stylesheet = false)
      @fh.write("<?xml version='1.0'?>\n")
      if add_stylesheet
        @fh.write(%Q{<?xml-stylesheet type="text/xsl" href="#{opts[:stylesheet]}"?>\n})
      end
      @fh.write("<collection xmlns='" + MARC_NS + "' " + "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' " + "xsi:schemaLocation='" + MARC_NS + " " + MARC_XSD + "'>")
      @fh.write("\n")
    end

    # a static method that takes a MARC::Record object
    # and returns a MARC-XML string
    def self.encode_to_xml_string(record, opts = {})
      @n ||= self.new_encoder
      @n.noko_encode(record, opts)
    end

    # write a record to the file or handle
    def write(record)
      @fh.write(encode_to_xml_string(record), "\n")
    end

    # close underlying filehandle
    def close
      @fh.write("</collection>")
      @fh.close
    end

    def noko_leader(record)
      # MARCXML only allows alphanumerics or spaces in the leader
      leader = record.leader.gsub(/[^\w|^\s]/, 'Z')

      # MARCXML is particular about last four characters; ILSes aren't
      leader[20..23] = "4500"

      # MARCXML doesn't like a space here so we need a filler character: Z
      leader[6] = "Z" if leader[6] == " "
      @doc.create_element('leader', leader)
    end

    def noko_controlfield(field)
      # We need a marker for invalid tag values (we use 00z)
      tag = if CTRLFIELD_TAG_RE.match?(field.tag) or MARC::ControlField.control_tag?(field.tag)
              field.tag
            else "00z"
            end
      @doc.create_element("controlfield", {tag: tag}, field.value)
    end

    def noko_datafield(field)
      ind1 = matches_single_char?(field.indicator1) ? field.indicator1 : 'z'
      ind2 = matches_single_char?(field.indicator2) ? field.indicator2 : 'z'
      attr = {tag: field.tag, ind1: ind1, ind2: ind2}
      df = @doc.create_element('datafield', attr)

      field.subfields.each do |subfield|
        df << noko_subfield(subfield)
      end
      df
    end

    def noko_subfield(subfield)
      # If marc is leniently parsed, we may have some dirty data; using
      # the blank subfield code should help us locate these later to fix
      code = SUBFIELD_CHAR_RE.match?(subfield.code) ? subfield.code : ' '
      @doc.create_element('subfield', {code: code}, subfield.value)
    end

    def noko_encode(record, opts = {})
      rec = @doc.create_element('record')
      rec.add_namespace(nil, MARC_NS) if opts[:include_namespace]
      rec << noko_leader(record)

      record.each do |field|
        case field
          when MARC::DataField
            rec << noko_datafield(field)
          when MARC::ControlField
            rec << noko_controlfield(field)
          else raise ArgumentError, "Encode can only handle fields of/subclassed from MARC::ControlField and MARC::DataField, not #{field.class}"
        end
      end
      rec.to_xml
    end

    def matches_single_char?(str)
      return false if str.nil?
      SINGLE_CHAR_RE.match?(str)
    end

    # The API for encode has always been to return an REXML object. While we don't need to do that when
    # writing out to a file, we need to preserve those semantics for now.
    #
    # Generally, use #encode_as_xml_string for speed if you're just doing MARC::XMLWriter.encode(rec).to_s anyway.
    def self.encode(*args)
      MARC::REXMLWriter.encode(*args)
    end
  end
end
