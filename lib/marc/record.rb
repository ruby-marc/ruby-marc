require 'forwardable'

module MARC

  # The FieldMap is an Array of DataFields and Controlfields.
  # It also contains a Hash representation
  # of the fields for faster lookups (under certain conditions)
  class FieldMap < Array
    attr_reader :tags
    attr_accessor :clean
    def initialize
      @tags = {}
      @clean = true
    end

    # Rebuild the HashWithChecksumAttribute with the current
    # values of the fields Array
    def reindex
      @tags = {}
      self.each_with_index do |field, i|
        @tags[field.tag] ||= []
        @tags[field.tag] << i
      end
      @clean = true
    end

    # Returns an array of all of the tags that appear in the record (not in the order they appear, however).
    def tag_list
      reindex unless @clean
      @tags.keys
    end

    # Returns an array of fields, in the order they appear, according to their tag.
    # The tags argument can be a string (e.g. '245'), an array (['100','700','800'])
    # or a range (('600'..'699')).
    def by_tag(tags)
      reindex unless @clean
      indices = @tags.values_at(*(@tags.keys & [*tags])).flatten.sort
      return [] if indices.empty?
      return self.values_at(*indices)
    end

    # Iterate over the #by_tag(filter) list
    def each_by_tag(tags)
      by_tag(tags).each {|x| yield x }
    end

    # Freeze for immutability, first reindexing if needed.
    # A frozen FieldMap is safe for concurrent access, and also
    # can more easily avoid accidental reindexing on even read-only use.
    def freeze
      self.reindex unless @clean
      super
    end

    # Set up the fields as dirty, unless it's frozen
    def dirty!
      self.clean = false unless self.frozen?
      self
    end

  end

  # A class that represents an individual MARC record. Every record
  # is made up of a collection of MARC::DataField objects.
  #
  # MARC::Record mixes in Enumerable to enable access to constituent
  # DataFields. For example, to return a list of all subject DataFields:
  #
  #   record.find_all {|field| field.tag =~ /^6../}
  #
  # The accessor 'fields' is also an Array of MARC::DataField objects which
  # the client can modify if neccesary.
  #
  #   record.fields.delete(field)
  #
  # Other accessor attribute: 'leader' for record leader as String
  #
  # == High-performance lookup by tag
  #
  # A frequent use case is looking up fields in a MARC record by tag, such
  # as 'all the 500 fields'.  Certain methods can use a hash keyed by
  # tag name for higher performance lookup by tag.  The hash is lazily
  # created on first access -- there is some cost of creating the hash,
  # testing shows you get a performance advantage to using the hash-based
  # methods if you are doing at least a dozen lookups.
  #
  #     record.fields("500")  # returns an array
  #     record.each_by_tag("500") {|field| ... }
  #     record.fields(['100', '700'])   # can also use an array in both methods
  #     record.each_by_tag( 600..699 )  # or a range
  #
  # == Freezing for thread-safety and high performance
  #
  # MARC::Record is not generally safe for sharing between threads.
  # Even if you think you are just acccessing it read-only,
  # you may accidentally trigger a reindex of the by-tag cache (see above).
  #
  # However, after you are done constructing a Record, you can mark
  # the `fields` array as immutable. This makes a Record safe for sharing
  # between threads for read-only use, and also helps you avoid accidentally
  # triggering a reindex, as accidental reindexes can harm by-tag
  # lookup performance.
  #
  #     record.fields.freeze
  class Record
    include Enumerable
    extend Forwardable

    # Delegate the enumeration and tag stuff to
    # the fields

    def_delegators :@fields, :each, :each_by_tag, :by_tag


    # the record fields
    #attr_reader :fields

    # the record leader
    attr_accessor :leader

    def initialize
      @fields = FieldMap.new
      # leader is 24 bytes
      @leader = ' ' * 24
      # leader defaults:
      # http://www.loc.gov/marc/bibliographic/ecbdldrd.html
      @leader[10..11] = '22'
      @leader[20..23] = '4500'
    end

    # add a field to the record
    #   record.append(MARC::DataField.new( '100', '2', '0', ['a', 'Fred']))

    def append(field)
      @fields.push(field)
      @fields.clean = false
    end

    alias_method :<<, :append


    # You can lookup the first field with a given tag using this shorthand:
    #   title = record['245']

    def [](tag)
      return self.find {|f| f.tag == tag}
    end


    # Provides a backwards compatible means to access the FieldMap.
    # No argument returns the FieldMap array in entirety.  Providing
    # a string, array or range of tags will return an array of fields
    # in the order they appear in the record.
    def fields(filter=nil)
      # In the abcense of a filter, we're returning the FieldMap object,
      # which the caller may mutate. We take the precaution of marking it
      # dirty
      if filter.nil?
        @fields.dirty!
      else
        @fields.reindex unless @fields.clean
        @fields.by_tag(filter)
      end
    end

    # Returns an array of all of the tags that appear in the record (not necessarily in the order they appear).
    def tags
      return @fields.tag_list
    end

    # Factory method for creating a MARC::Record from MARC21 in
    # transmission format.
    #
    #   record = MARC::Record.new_from_marc(marc21)
    #
    # in cases where you might be working with somewhat flawed
    # MARC data you may want to use the :forgiving parameter which
    # will bypass using field byte offsets and simply look for the
    # end of field byte to figure out the end of fields.
    #
    #  record = MARC::Record.new_from_marc(marc21, :forgiving => true)

    def self.new_from_marc(raw, params={})
      return MARC::Reader.decode(raw, params)
    end


    # Returns a record in MARC21 transmission format (ANSI Z39.2).
    # Really this is just a wrapper around MARC::MARC21::encode
    #
    #   marc = record.to_marc()

    def to_marc
      return MARC::Writer.encode(self)
    end

    # Handy method for returning the MARCXML serialization for a
    # MARC::Record object. You'll get back a REXML::Document object.
    # Really this is just a wrapper around MARC::XMLWriter::encode
    #
    #   xml_doc = record.to_xml()

    def to_xml
      return MARC::XMLWriter.encode(self, :include_namespace => true)
    end

    # Handy method for returning a hash mapping this records values
    # to the Dublin Core.
    #
    #   dc = record.to_dublin_core()
    #   print dc['title']

    def to_dublin_core
      return MARC::DublinCore.map(self)
    end

    # Return a marc-hash version of the record
    def to_marchash
      return {
        'type' => 'marc-hash',
        'version' => [MARCHASH_MAJOR_VERSION, MARCHASH_MINOR_VERSION],
        'leader' => self.leader,
        'fields' => self.map {|f| f.to_marchash}
      }
    end #to_hash

    # Factory method for creating a new MARC::Record from
    # a marchash object
    #
    # record = MARC::Record->new_from_marchash(mh)

    def self.new_from_marchash(mh)
      r = self.new()
      r.leader = mh['leader']
      mh['fields'].each do |f|
        if (f.length == 2)
          r << MARC::ControlField.new(f[0], f[1])
        elsif
          r << MARC::DataField.new(f[0], f[1], f[2], *f[3])
        end
      end
      return r
    end



    # Returns a (roundtrippable) hash representation for MARC-in-JSON
    def to_hash
      record_hash = {'leader'=>@leader, 'fields'=>[]}
      @fields.each do |field|
        record_hash['fields'] << field.to_hash
      end
      record_hash
    end

    def self.new_from_hash(h)
      r = self.new
      r.leader = h['leader']
      if h['fields']
        h['fields'].each do |position|
          position.each_pair do |tag, field|
            if field.is_a?(Hash)
              f = MARC::DataField.new(tag, field['ind1'], field['ind2'])
              field['subfields'].each do | pos |
                pos.each_pair do |code, value|
                  f.append MARC::Subfield.new(code, value)
                end
              end
              r << f
            else
              r << MARC::ControlField.new(tag, field)
            end
          end
        end
      end
      return r
    end
    # Returns a string version of the record, suitable for printing

    def to_s
      str = "LEADER #{leader}\n"
      self.each do |field|
        str += field.to_s() + "\n"
      end
      return str
    end


    # For testing if two records can be considered equal.

    def ==(other)
      return self.to_s == other.to_s
    end


    # Handy for using a record in a regex:
    #   if record =~ /Gravity's Rainbow/ then print "Slothrop" end

    def =~(regex)
      return self.to_s =~ regex
    end

  end
end
