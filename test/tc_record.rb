require 'test/unit'
require 'marc'
require 'xmlsimple'

 def xml_cmp a, b
   eq_all_but_zero = Object.new.instance_eval do
     def ==(other)
       Integer(other) == 0 ? false : true
     end
     self
   end
   a = XmlSimple.xml_in(a.to_s, 'normalisespace' => eq_all_but_zero) 
   b = XmlSimple.xml_in(b.to_s, 'normalisespace' => eq_all_but_zero) 
   a == b
 end

class TestRecord < Test::Unit::TestCase

    def test_constructor
        r = MARC::Record.new()
        assert_equal(r.class, MARC::Record)
    end

    def test_xml
      r = get_record()
      doc = r.to_xml
      assert_kind_of REXML::Element, doc
      assert xml_cmp("<record xmlns='http://www.loc.gov/MARC21/slim'><leader>      Z   22        4500</leader><datafield tag='100' ind1='2' ind2='0'><subfield code='a'>Thomas, Dave</subfield></datafield><datafield tag='245' ind1='0' ind2='4'><subfield code='The Pragmatic Programmer'></subfield></datafield></record>", doc.to_s)
    end

    def test_append_field
        r = get_record()
        assert_equal(r.fields.length(), 2)
    end

    def test_iterator
        r = get_record()
        count = 0
        r.each {|f| count += 1}
        assert_equal(count,2)
    end

    def test_decode
        raw = IO.read('test/one.dat')
        r = MARC::Record::new_from_marc(raw)
        assert_equal(r.class, MARC::Record)
        assert_equal(r.leader, '00755cam  22002414a 4500')
        assert_equal(r.fields.length(), 18)
        assert_equal(r.find {|f| f.tag == '245'}.to_s,
            '245 10 $a ActivePerl with ASP and ADO / $c Tobias Martinsson. ')
    end

    def test_decode_forgiving
        raw = IO.read('test/one.dat')
        r = MARC::Record::new_from_marc(raw, :forgiving => true)
        assert_equal(r.class, MARC::Record)
        assert_equal(r.leader, '00755cam  22002414a 4500')
        assert_equal(r.fields.length(), 18)
        assert_equal(r.find {|f| f.tag == '245'}.to_s,
            '245 10 $a ActivePerl with ASP and ADO / $c Tobias Martinsson. ')
    end

    def test_encode
        r1 = MARC::Record.new()
        r1.append(MARC::DataField.new('100', '2', '0', ['a', 'Thomas, Dave']))
        r1.append(MARC::DataField.new('245', '0', '0', ['a', 'Pragmatic Programmer']))
        raw = r1.to_marc()
        r2 = MARC::Record::new_from_marc(raw)
        assert_equal(r1, r2)
    end

    def test_lookup_shorthand
        r = get_record
        assert_equal(r['100']['a'], 'Thomas, Dave')
    end

    def get_record
        r = MARC::Record.new()
        r.append(MARC::DataField.new('100', '2', '0', ['a', 'Thomas, Dave'])) 
        r.append(MARC::DataField.new('245', '0', '4', ['The Pragmatic Programmer']))
        return r
    end
    
    def test_field_index
      raw = IO.read('test/random_tag_order.dat')
      r = MARC::Record.new_from_marc(raw)
      assert_kind_of(Array, r.fields)
      assert_kind_of(Array, r.tags)
      assert_equal(['001','005','007','008','010','028','035','040','050','245','260','300','500','505','511','650','700','906','953','991'], r.tags.sort)
      assert_kind_of(Array, r.fields('035'))
      raw2 = IO.read('test/random_tag_order2.dat')
      r2 = MARC::Record.new_from_marc(raw2)
      assert_equal(6, r2.fields('500').length)     
      # Test passing an array to Record#fields
      assert_equal(3, r.fields(['500','505', '510', '511']).length) 
      # Test passing a Range to Record#fields
      assert_equal(9, r.fields(('001'..'099')).length)
    end
    
    def test_field_index_order
      raw = IO.read('test/random_tag_order.dat')
      r = MARC::Record.new_from_marc(raw)      
      notes = ['500','505','511']
      r.fields(('500'..'599')).each do |f|
        assert_equal(notes.pop, f.tag)
      end
      
      
      raw2 = IO.read('test/random_tag_order2.dat')
      r2 = MARC::Record.new_from_marc(raw2)      
      
      fields = ['050','042','010','028','024','035','041','028','040','035','008','007','005','001']
      r2.each_by_tag(('001'..'099')) do |f|
        assert_equal(fields.pop, f.tag)
      end      
      
      five_hundreds = r2.fields('500')
      assert_equal(five_hundreds.first['a'], '"Contemporary blues" interpretations of previously released songs; written by Bob Dylan.')
      assert_equal(five_hundreds.last['a'], 'Composer and program notes in container.')
    end


    # Some tests for the internal FieldMap hash, normally
    # an implementation detail, but things get tricky and we need
    # tests to make sure we're good. Some of these you might
    # change if you change FieldMap caching implementation or contract/API. 
    def test_direct_change_dirties_fieldmap
      # if we ask for #fields directly, and mutate it
      # with it's own methods, does any cache update?
      r = MARC::Record.new
      assert r.fields('500').empty? 
      r.fields.push MARC::DataField.new('500', ' ', ' ', ['a', 'notes'])
      assert ! r.fields('500').empty?, "New 505 directly added to #fields is picked up"

      # Do it again, make sure #[] works too
      r = MARC::Record.new
      assert r['500'].nil?
      r.fields.push MARC::DataField.new('500', ' ', ' ', ['a', 'notes'])
      assert r['500'], "New 505 directly added to #fields is picked up"
    end

    def test_frozen_fieldmap
      r = MARC::Record.new
      r.fields.push MARC::DataField.new('500', ' ', ' ', ['a', 'notes'])

      r.fields.freeze

      r.fields.inspect
      r.fields
      assert ! r.fields('500').empty?

      assert r.fields.instance_variable_get("@clean"), "FieldMap still marked clean"

    end

    def test_remove_field
      r = MARC::Record.new
      r.fields.push MARC::DataField.new('100', '0', '1', ['a', 'Author'])
      r.fields.push MARC::DataField.new('245', '1', '0', ['a', 'Title'])
      r.fields.push MARC::DataField.new('500', '0', '1', ['a', 'Note 1'])
      r.fields.push MARC::DataField.new('500', '0', '2', ['a', 'Note 2'])
      assert_equal(r.fields('500').count, 2)
      r.remove('500')
      assert_equal(r.fields('500').count, 0)
    end

    def test_remove_specific_field
      r = MARC::Record.new
      r.fields.push MARC::DataField.new('100', '0', '1', ['a', 'Author'])
      r.fields.push MARC::DataField.new('245', '1', '0', ['a', 'Title'])
      r.fields.push MARC::DataField.new('500', '0', '4', ['a', 'Note 1'])
      r.fields.push MARC::DataField.new('500', '0', '5', ['a', 'Note 2'])
      assert_equal(r.fields('500').count, 2)

      specific_field = r.fields.find { |f| f.tag == '500' && f.indicator2 == '4' }
      r.remove(specific_field)

      assert_equal(r.fields('500').count, 1)
      assert_equal(r['500']['a'], 'Note 2')
    end

    def test_remove_field_by_index
      r = MARC::Record.new
      r.fields.push MARC::DataField.new('100', '0', '1', ['a', 'Author'])
      r.fields.push MARC::DataField.new('245', '1', '0', ['a', 'Title'])
      r.fields.push MARC::DataField.new('500', '0', '4', ['a', 'Note 1'])
      r.fields.push MARC::DataField.new('500', '0', '5', ['a', 'Note 2'])
      assert_equal(r.fields('500').count, 2)

      r.remove_at(2)

      assert_equal(r.fields('500').count, 1)
      assert_equal(r['500']['a'], 'Note 2')
    end
end
