require "rexml/document"
require "rexml/text"
require "rexml/formatters/default"

module MARC
  # A class for writing MARC records as MARCXML.
  # BIG CAVEAT! XMLWriter will *not* convert your MARC8 to UTF8
  # bug the authors to do this if you need it

  class XMLWriter
    # the constructor which you must pass a file path
    # or an object that responds to a write message
    # the second argument is a hash of options, currently
    # only supporting one option, stylesheet
    #
    # writer = XMLWriter.new 'marc.xml', :stylesheet => 'style.xsl'
    # writer.write record
    #

    COLLECTION_TAG = %(<collection xmlns='#{MARC_NS}'
      xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
      xsi:schemaLocation="#{MARC_NS} #{MARC_XSD}">).freeze

    def initialize(file, opts = {}, &blk)
      @writer = REXML::Formatters::Default.new
      if file.instance_of?(String)
        @fh = File.new(file, "w")
      elsif file.respond_to?(:write)
        @fh = file
      else
        raise ArgumentError, "must pass in file name or handle"
      end

      @stylesheet = opts[:stylesheet]

      @fh.write("<?xml version='1.0'?>\n")
      @fh.write(stylesheet_tag)
      @fh.write(COLLECTION_TAG)
      @fh.write("\n")

      if block_given?
        blk.call(self)
        self.close
      end
    end

    def stylesheet_tag
      if @stylesheet
        %(<?xml-stylesheet type="text/xsl" href="#{@stylesheet}"?>\n)
      else
        ""
      end
    end

    # write a record to the file or handle

    def write(record)
      @writer.write(MARC::XMLWriter.encode(record), @fh)
      @fh.write("\n")
    end

    # close underlying filehandle

    def close
      @fh.write("</collection>")
      @fh.close
    end

    def self.fix_leader(leader)
      fixed_leader = leader.gsub(/[^\w|^\s]/, "Z")

      # The leader must have at least 24 characters
      fixed_leader = fixed_leader.ljust(24) if fixed_leader.length < 24

      # MARCXML is particular about last four characters; ILSes aren't
      if fixed_leader[20..23] != "4500"
        fixed_leader[20..23] = "4500"
      end

      # MARCXML doesn't like a space here so we need a filler character: Z
      if fixed_leader[6..6] == " "
        fixed_leader[6..6] = "Z"
      end

      fixed_leader
    end

    # a static method that accepts a MARC::Record object
    # and returns a REXML::Document for the XML serialization.
    def self.encode(record, opts = {})
      single_char = Regexp.new('[\da-z ]{1}')
      subfield_char = Regexp.new('[\dA-Za-z!"#$%&\'()*+,-./:;<=>?{}_^`~\[\]\\\]{1}')
      control_field_tag = Regexp.new("00[1-9A-Za-z]{1}")

      # Right now, this writer handles input from the strict and
      # lenient MARC readers. Because it can get 'loose' MARC in, it
      # attempts to do some cleanup on data values that are not valid
      # MARCXML.

      # TODO? Perhaps the 'loose MARC' checks should be split out
      # into a tolerant MARCXMLWriter allowing the main one to skip
      # this extra work.

      # TODO: At the very least there should be some logging
      # to record our attempts to account for less than perfect MARC.

      e = REXML::Element.new("record")
      e.add_namespace(MARC_NS) if opts[:include_namespace]

      leader_element = REXML::Element.new("leader")
      leader_element.add_text(fix_leader(record.leader))
      e.add_element(leader_element)

      record.each do |field|
        if field.instance_of?(MARC::DataField)
          datafield_elem = REXML::Element.new("datafield")

          ind1 = field.indicator1
          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind1 value should help us locate these later to fix
          ind1 = "z" if ind1.nil? || !ind1.match?(single_char)
          ind2 = field.indicator2
          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind2 value should help us locate these later to fix

          ind2 = "z" if field.indicator2.nil? || !ind2.match?(single_char)

          datafield_elem.add_attributes({
            "tag" => field.tag,
            "ind1" => ind1,
            "ind2" => ind2
          })

          field.subfields.each do |subfield|
            subfield_element = REXML::Element.new("subfield")

            code = subfield.code
            # If marc is leniently parsed, we may have some dirty data; using
            # the blank subfield code should help us locate these later to fix
            code = " " if subfield.code.match(subfield_char).nil?

            subfield_element.add_attribute("code", code)
            text = subfield.value
            subfield_element.add_text(text)
            datafield_elem.add_element(subfield_element)
          end

          e.add_element datafield_elem
        elsif field.instance_of?(MARC::ControlField)
          control_element = REXML::Element.new("controlfield")

          tag = field.tag
          # We need a marker for invalid tag values (we use 000)
          tag = "00z" unless tag.match(control_field_tag) || MARC::ControlField.control_tag?(tag)

          control_element.add_attribute("tag", tag)
          text = field.value
          control_element.add_text(text)
          e.add_element(control_element)
        end
      end

      # return xml
      e
    end
  end
end
