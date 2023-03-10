require "test/unit"
require "marc"

class TestCustomRecord < Test::Unit::TestCase

  module SimpleMARCSemantics
    def title
      self["245"].select { |sf| %w(a b d e k f g n p).include?(sf.code) }
                 .map { |sf| sf.value }
                 .join(" ")
                 .gsub(/[\s\/;.,]+\Z/, '')
    end
  end

  class MyRecord < MARC::Record
    include SimpleMARCSemantics
  end

  def test_basics
    reader = MARC::ForgivingReader.new("test/batch.dat", record_class: MyRecord)
    rec = reader.first
    assert_equal("ActivePerl with ASP and ADO", rec.title)
  end

end
