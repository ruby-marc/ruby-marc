module MARC
  # A class for mapping MARC records to Dublin Core

  class DublinCore

    class DataFieldExtractor
      attr_accessor :tag, :ind1, :ind2, :include_codes, :exclude_codes

      def initialize(tag:, ind1: nil, ind2: nil, include_codes: [], exclude_codes: [])
        @tag = parse_value(tag)
        @ind1 = parse_value(ind1)
        @ind2 = parse_value(ind2)
        @include_codes = include_codes.kind_of?(Array) ? include_codes : include_codes.chars
        @exclude_codes = exclude_codes.kind_of?(Array) ? exclude_codes : exclude_codes.chars
        yield self if block_given?
      end

      def parse_value(tag)
        case tag
          when Numeric
            tag.to_s
          when Array
            Regexp.union(tag)
          else
            tag
        end
      end

      # @param [MARC::DataField] field
      def indicators_match?(field)
        ind1match = ind1.nil? or (ind1 === field.indicator1)
        ind2match = ind2.nil? or (ind2 === field.indicator2)
        ind1match and ind2match
      end

      def sfmatch?(sf)
        (include_codes.empty? or include_codes.include?(sf.code)) and
          (exclude_codes.empty? or !exclude_codes.include?(sf.code))
      end

      # @param [MARC::DataField] field
      def includes?(field)
        tag === field.tag and indicators_match?(field)
      end

      # @param [MARC::DataField] field
      def extract(field)
        return nil unless self.includes?(field)
        field.subfields.select{|sf| sfmatch?(sf)}.map(&:value).join(" ").gsub(/\s+/, ' ').gsub(/\A(.*?)[;\/]+\Z/, '\1').strip
      end
    end

    class DCFieldSpec
      attr_reader :tagmatcher
      def initialize(*datafield_specs)
        @datafield_specs = datafield_specs
        @tagmatcher = Regexp.union(@datafield_specs.flatten.map(&:tag))
      end

      #@param [MARC::Record} record]
      def extract(record)
        candidates = record.fields.select{|f| @tagmatcher.match?(f.tag)}
        candidates.flat_map{|f| @datafield_specs.map{|dfspec| dfspec.extract(f)}}.compact
      end
    end

    # MAPPING ARE TAKEN FROM https://www.loc.gov/marc/marc2dc.html
    # WITH SOME CODE RESTRICTIONS
    DCSPECS = {
      'title' =>  DCFieldSpec.new(DataFieldExtractor.new(tag: %w(245 246), include_codes: "abdefgknp")),

      "creator" => DCFieldSpec.new(
        DataFieldExtractor.new(tag: %w(100 700), include_codes: "abcdjq"),
        DataFieldExtractor.new(tag: %w(110 710), include_codes: "abcd"),
        DataFieldExtractor.new(tag: %w(111 711), include_codes: "acden")),

      "subject" => DCFieldSpec.new(
        DataFieldExtractor.new(tag: %w(600 610 611 630), include_codes: "abcdefghjklmnopqrstuvxyz"),
        DataFieldExtractor.new(tag: %w(650 653), include_codes: "abkcdevxyz")
      ),

      "description" =>  DCFieldSpec.new(
        DataFieldExtractor.new(tag: /5\d\d/)
      ),

      "publisher" => CFieldSpec.new(
        DataFieldExtractor.new(tag: "260", include_codes: "ab")
      ),

      "date" => CFieldSpec.new(
        DataFieldExtractor.new(tag: "260", include_codes: "cg")
      ),
    }


    def self.map(record)
      dc_hash = {}
      dc_hash["title"] = get_field_value(record["245"]["a"])

      # Creator
      ["100", "110", "111", "700", "710", "711", "720"].each do |field|
        dc_hash["creator"] ||= []
        dc_hash["creator"] << get_field_value(record[field])
      end

      # Subject
      ["600", "610", "611", "630", "650", "653"].each do |field|
        dc_hash["subject"] ||= []
        dc_hash["subject"] << get_field_value(record[field])
      end

      # Description
      ("500".."599").each do |field|
        next if ["506", "530", "540", "546"].include?(field)
        dc_hash["description"] ||= []
        dc_hash["description"] << get_field_value(record[field])
      end

      dc_hash["publisher"] = begin
        get_field_value(record["260"]["a"]["b"])
      rescue
        nil
      end
      dc_hash["date"] = begin
        get_field_value(record["260"]["c"])
      rescue
        nil
      end
      dc_hash["type"] = get_field_value(record["655"])
      dc_hash["format"] = begin
        get_field_value(record["856"]["q"])
      rescue
        nil
      end
      dc_hash["identifier"] = begin
        get_field_value(record["856"]["u"])
      rescue
        nil
      end
      dc_hash["source"] = begin
        get_field_value(record["786"]["o"]["t"])
      rescue
        nil
      end
      dc_hash["language"] = get_field_value(record["546"])

      dc_hash["relation"] = []
      dc_hash["relation"] << get_field_value(record["530"])
      ("760".."787").each do |field|
        dc_hash["relation"] << get_field_value(record[field]["o"]["t"])
      rescue
        nil
      end

      ["651", "752"].each do |field|
        dc_hash["coverage"] ||= []
        dc_hash["coverage"] << get_field_value(record[field])
      end

      ["506", "540"].each do |field|
        dc_hash["rights"] ||= []
        dc_hash["rights"] << get_field_value(record[field])
      end

      dc_hash.keys.each do |key|
        dc_hash[key].flatten! if dc_hash[key].respond_to?(:flatten!)
        dc_hash[key].compact! if dc_hash[key].respond_to?(:compact!)
      end

      dc_hash
    end

    def self.get_field_value(field)
      return if field.nil?

      if !field.is_a?(String) && field.respond_to?(:each)
        values = []
        field.each do |element|
          values << get_field_value(element)
        end
        values
      else
        return field if field.is_a?(String)
        return field.value if field.respond_to?(:value)
      end
    end
  end
end
