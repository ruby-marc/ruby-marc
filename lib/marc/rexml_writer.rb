# frozen_string_literal: true

require 'rexml'

module MARC
  # This is the original REXML-based encoder. We still need it because
  # the API for Record#to_xml and MARC::XMLWriter.encode is to return
  # a REXML::Document object instead of the MARC-XML string.
  class REXMLWriter
    def self.encode(record, opts = {})
      singleChar = Regexp.new('[\da-z ]{1}')
      subfieldChar = Regexp.new('[\dA-Za-z!"#$%&\'()*+,-./:;<=>?{}_^`~\[\]\\\]{1}')
      ctrlFieldTag = Regexp.new('00[1-9A-Za-z]{1}')

      # Right now, this writer handles input from the strict and
      # lenient MARC readers. Because it can get 'loose' MARC in, it
      # attempts to do some cleanup on data values that are not valid
      # MARCXML.

      # TODO? Perhaps the 'loose MARC' checks should be split out
      # into a tolerant MARCXMLWriter allowing the main one to skip
      # this extra work.

      # TODO: At the very least there should be some logging
      # to record our attempts to account for less than perfect MARC.

      e = REXML::Element.new('record')
      e.add_namespace(MARC_NS) if opts[:include_namespace]

      # MARCXML only allows alphanumerics or spaces in the leader
      record.leader.gsub!(/[^\w|^\s]/, 'Z')

      # MARCXML is particular about last four characters; ILSes aren't
      if (record.leader[20..23] != "4500")
        record.leader[20..23] = "4500"
      end

      # MARCXML doesn't like a space here so we need a filler character: Z
      if (record.leader[6..6] == " ")
        record.leader[6..6] = "Z"
      end

      leader = REXML::Element.new("leader")
      leader.add_text(record.leader)
      e.add_element(leader)

      record.each do |field|
        if field.class == MARC::DataField
          datafield_elem = REXML::Element.new("datafield")

          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind1 value should help us locate these later to fix
          if field.indicator1.nil? || (field.indicator1.match(singleChar) == nil)
            field.indicator1 = 'z'
          end

          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind2 value should help us locate these later to fix
          if field.indicator2.nil? || (field.indicator2.match(singleChar) == nil)
            field.indicator2 = 'z'
          end

          datafield_elem.add_attributes({"tag" => field.tag, "ind1" => field.indicator1, "ind2" => field.indicator2
                                        })

          for subfield in field.subfields
            subfield_element = REXML::Element.new("subfield")

            # If marc is leniently parsed, we may have some dirty data; using
            # the blank subfield code should help us locate these later to fix
            if (subfield.code.match(subfieldChar) == nil)
              subfield.code = ' '
            end

            subfield_element.add_attribute("code", subfield.code)
            text = subfield.value
            subfield_element.add_text(text)
            datafield_elem.add_element(subfield_element)
          end

          e.add_element datafield_elem
        elsif field.class == MARC::ControlField
          control_element = REXML::Element.new("controlfield")

          # We need a marker for invalid tag values (we use 000)
          unless field.tag.match(ctrlFieldTag) or MARC::ControlField.control_tag?(ctrlFieldTag)
            field.tag = "00z"
          end

          control_element.add_attribute("tag", field.tag)
          text = field.value
          control_element.add_text(text)
          e.add_element(control_element)
        end
      end

      # return xml
      return e
    end

  end
end