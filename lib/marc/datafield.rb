require 'forwardable'

module MARC
  # MARC records contain data fields, each of which has a tag,
  # indicators and subfields. Tags for data fields must are all
  # three-character tags that are not control fields (generally,
  # any numeric tag greater than 009).
  #
  # Accessor attributes: tag, indicator1, indicator2
  #
  # DataField mixes in Enumerable to enable access to it's constituent
  # Subfield objects. For instance, if you have a DataField representing
  # a 856 tag, and want to find all 'z' subfields:
  #
  #   subfield_z = field.find_all {|subfield| subfield.code == 'z'}
  #
  # Also, the accessor 'subfields' is an array of MARC::Subfield objects
  # which can be accessed or modified by the client directly if
  # neccesary.

  class DataField
    include Enumerable
    extend Forwardable

    # Enumerate over the subfields
    def_delegators :@subfields, :each

    # The tag for the field
    attr_accessor :tag

    # The first indicator
    attr_accessor :indicator1

    # The second indicator
    attr_accessor :indicator2

    # A list of MARC::Subfield objects
    attr_accessor :subfields


    # Create a new field with tag, indicators and subfields.
    # Subfields are passed in as comma separated list of
    # MARC::Subfield objects,
    #
    #   field = MARC::DataField.new('245','0','0',
    #     MARC::Subfield.new('a', 'Consilience :'),
    #     MARC::Subfield.new('b', 'the unity of knowledge '),
    #     MARC::Subfield.new('c', 'by Edward O. Wilson.'))
    #
    # or using a shorthand:
    #
    #   field = MARC::DataField.new('245','0','0',
    #     ['a', 'Consilience :'],['b','the unity of knowledge '],
    #     ['c', 'by Edward O. Wilson.'] )

    def initialize(tag, i1=' ', i2=' ', *subfields)
      # if the tag is less than 3 characters long and
      # the string is all numeric then we pad with zeros
      if tag.length < 3 and /^[0-9]*$/ =~ tag
        @tag = "%03d" % tag
      else
        @tag = tag
      end
      # can't allow nil to be passed in or else it'll
      # screw us up later when we try to encode
      @indicator1 = i1 == nil ? ' ' : i1
      @indicator2 = i2 == nil ? ' ' : i2

      @subfields = []

      # must use MARC::ControlField for tags < 010 or
      # those in MARC::ControlField#extra_control_fields

      if MARC::ControlField.control_tag?(@tag)
        raise MARC::Exception.new(),
          "MARC::DataField objects can't have ControlField tag '" + @tag + "')"
      end

      # allows MARC::Subfield objects to be passed directly
      # or a shorthand of ['a','Foo'], ['b','Bar']
      subfields.each do |subfield|
        case subfield
        when MARC::Subfield
          @subfields.push(subfield)
        when Array
          if subfield.length > 2
            raise MARC::Exception.new(),
              "arrays must only have 2 elements: " + subfield.to_s
          end
          @subfields.push(
            MARC::Subfield.new(subfield[0],subfield[1]))
        else
          raise MARC::Exception.new(),
            "invalid subfield type #{subfield.class}"
        end
      end
    end


    # Returns a string representation of the field such as:
    #  245 00 $aConsilience :$bthe unity of knowledge $cby Edward O. Wilson.

    def to_s
      str = "#{tag} "
      str += "#{indicator1}#{indicator2} "
      @subfields.each { |subfield| str += subfield.to_s }
      return str
    end

    # Turn into a marc-hash structure
    def to_marchash
      return [@tag, @indicator1, @indicator2, @subfields.map {|sf| [sf.code, sf.value]} ]
    end


    # Create a datafield from a marc-in-json style tag/datahash pair
    def self.new_from_marc_in_hash(tag,datahash)
      f = self.new(tag, datahash['ind1'], datahash['ind2'])
      datahash['subfields'].each do |sf|
        code,data = sf.first
        f.append MARC::Subfield.new(code,data)
      end
      f
    end
    # Turn the variable field and subfields into a hash for MARC-in-JSON

    def to_hash
      { @tag =>
        {
         'ind1' => @indicator1,
         'ind2' => @indicator2,
         'subfields' => @subfields.map{|x| {x.code => x.value}}
        }
      }
    end

    # Add a subfield (MARC::Subfield) to the field
    #    field.append(MARC::Subfield.new('a','Dave Thomas'))

    def append(subfield)
      @subfields.push(subfield)
    end

    # You can lookup subfields with this shorthand. Note it
    # will return a string and not a MARC::Subfield object.
    #
    # NOTE: the value of only the *first* subfield is returned
    #   subfield = field['a']

    def [](code)
      subfield = self.detect {|s| s.code == code}
      return subfield.value if subfield
      return nil
    end


    def codes(dedup=true)
      codes = subfields.map(&:code)
      codes.uniq! if dedup
      codes
    end

    # Two fields are equal if their tag, indicators and
    # subfields are all equal.

    def ==(other)
      tag == other.tag and
        indicator1 == other.indicator1 and
        indicator2 == other.indicator2 and
        subfields.size == other.subfields.size and
        subfields.zip(other.subfields).all?{|a| a[0] == a[1] }
    end


    # To support regex matching with fields
    #
    #   if field =~ /Huckleberry/ ...

    def =~(regex)
      return self.to_s =~ regex
    end


    # to get the field as a string, without the tag and indicators
    # useful in situations where you want a legible version of the field
    #
    # print record['245'].value

    def value
      return(@subfields.map {|s| s.value} .join '')
    end

  end
end
