require "test/unit"
require "marc"

class JSONLTestCase < Test::Unit::TestCase
  def test_round_trip
    tempfile = "test/batch.jsonl"
    records = MARC::Reader.new("test/batch.dat").to_a
    jsonl_writer = MARC::JSONLWriter.new(tempfile)
    records.each { |r| jsonl_writer.write(r) }
    jsonl_writer.close

    jsonl_reader = MARC::JSONLReader.new(tempfile)
    jsonl_reader.each_with_index do |r, i|
      assert_equal(records[i], r)
    end
  ensure
    File.unlink(tempfile)
  end
end
