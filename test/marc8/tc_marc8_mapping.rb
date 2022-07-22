require "test/unit"
require "marc"
require "marc/marc8/map_to_unicode"

class TestMarc8Mapping < Test::Unit::TestCase
  def test_codesets_just_exist
    assert MARC::Marc8::MapToUnicode::CODESETS
    assert MARC::Marc8::MapToUnicode::CODESETS[0x34]
    assert MARC::Marc8::MapToUnicode::CODESETS[0x34][0xa1]
  end
end
