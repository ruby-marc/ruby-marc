require 'test/unit'
require 'marc'

class TestRecord < Test::Unit::TestCase

    def test_constructor
        r = MARC::Record.new()
        assert_equal(r.class, MARC::Record)
    end

    def test_xml
      r = get_record()
      doc = r.to_xml
      assert_kind_of REXML::Element, doc
      if RUBY_VERSION < '1.9.0'
        assert_equal "<record xmlns='http://www.loc.gov/MARC21/slim'><leader>      Z   22        4500</leader><datafield tag='100' ind1='2' ind2='0'><subfield code='a'>Thomas, Dave</subfield></datafield><datafield tag='245' ind1='0' ind2='4'><subfield code='a'>The Pragmatic Programmer</subfield></datafield></record>", doc.to_s
      else
        # REXML inexplicably sorts the attributes alphabetically in Ruby 1.9
        assert_equal "<record xmlns='http://www.loc.gov/MARC21/slim'><leader>      Z   22        4500</leader><datafield ind1='2' ind2='0' tag='100'><subfield code='a'>Thomas, Dave</subfield></datafield><datafield ind1='0' ind2='4' tag='245'><subfield code='a'>The Pragmatic Programmer</subfield></datafield></record>", doc.to_s        
      end
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
        r.append(MARC::DataField.new('245', '0', '4', ['a', 'The Pragmatic Programmer']))
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

    def test_new_from_s
      r = get_record
      s = r.to_s
      assert_equal(s, MARC::Record.new_from_s(s).to_s)
    end

end
