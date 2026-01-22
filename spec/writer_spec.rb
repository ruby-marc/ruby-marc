require 'spec_helper'
require 'stringio'

RSpec.describe MARC::Writer do
  it "writes and reads MARC records properly" do
    writer = MARC::Writer.new("test/writer.dat")
    record = MARC::Record.new
    record.append(MARC::DataField.new("245", "0", "1", ["a", "foo"]))
    writer.write(record)
    writer.close

    # read it back to make sure
    reader = MARC::Reader.new("test/writer.dat")
    records = reader.entries
    expect(records.length).to eq(1)
    expect(records[0]).to eq(record)

    # cleanup
    File.unlink("test/writer.dat")
  end

  if "".respond_to?(:encoding)
    it "handles mixed encodings properly" do
      writer = MARC::Writer.new("test/writer.dat")

      # MARC::Writer should just happily write out whatever bytes you give it, even
      # mixing encodings that can't be mixed. We ran into an actual example mixing
      # MARC8 (tagged ruby binary) and UTF8, we want it to be written out.

      record = MARC::Record.new

      record.append MARC::DataField.new("700", "0", " ", ["a", "Nhouy Abhay,".force_encoding("BINARY")], ["c", "Th\xE5ao,".force_encoding("BINARY")], ["d", "1909-"])
      record.append MARC::DataField.new("700", "0", " ", ["a", "Somchin P\xF8\xE5o. Ngin,".force_encoding("BINARY")])

      record.append MARC::DataField.new("100", "0", "0", ["a", "\xE5angkham. ".force_encoding("BINARY")])
      record.append MARC::DataField.new("245", "1", "0", ["b", "chef-d'oeuvre de la litt\xE2erature lao".force_encoding("BINARY")])

      # One in UTF8 and marked
      record.append MARC::DataField.new("999", "0", "1", ["a", "chef-d'ocuvre de la littU+FFC3\U+FFA9rature".force_encoding("UTF-8")])

      writer.write(record)
      writer.close
    ensure
      File.unlink("test/writer.dat") if File.exist?("test/writer.dat")
    end
  end

  it "supports oversized records when configured" do
    too_long_record = MARC::Record.new
    1.upto(1001) do
      too_long_record.append MARC::DataField.new("500", " ", " ", ["a", "A really long record.1234567890123456789012345678901234567890123456789012345678901234567890123456789"])
    end

    wbuffer = StringIO.new("", "w")
    writer = MARC::Writer.new(wbuffer)
    writer.allow_oversized = true

    writer.write(too_long_record)
    writer.close

    expect(wbuffer.string.slice(0, 5)).to eq("00000")

    rbuffer = StringIO.new(wbuffer.string.dup)

    # Forgiving reader will, round trippable
    new_record = MARC::Reader.decode(rbuffer.string, forgiving: true)
    expect(new_record).to eq(too_long_record)

    # Test in the middle of a MARC file
    good_record = MARC::Record.new
    good_record.append MARC::DataField.new("500", " ", " ", ["a", "A short record"])
    wbuffer = StringIO.new("", "w")
    writer = MARC::Writer.new(wbuffer)
    writer.allow_oversized = true

    writer.write(good_record)
    writer.write(too_long_record)
    writer.write(good_record)

    rbuffer = StringIO.new(wbuffer.string.dup)
    reader = MARC::ForgivingReader.new(rbuffer)
    records = reader.to_a

    expect(records.length).to eq(3)
    expect(records[0]).to eq(good_record)
    expect(records[2]).to eq(good_record)
    expect(records[1]).to eq(too_long_record)
  end

  it "raises exception for oversized records by default" do
    too_long_record = MARC::Record.new
    1.upto(1001) do
      too_long_record.append MARC::DataField.new("500", " ", " ", ["a", "A really long record.1234567890123456789012345678901234567890123456789012345678901234567890123456789"])
    end

    wbuffer = StringIO.new("", "w")
    writer = MARC::Writer.new(wbuffer)

    expect { writer.write too_long_record }.to raise_error(MARC::Exception)
  end

  it "handles forgiving writing" do
    marc = "00305cam a2200133 a 4500001000700000003000900007005001700016008004100033008004100074035002500115245001700140909001000157909000400167\036635145\036UK-BiLMS\03620060329173705.0\036s1982iieng6                  000 0 eng||\036060116|||||||||xxk                 eng||\036  \037a(UK-BiLMS)M0017366ZW\03600\037aTest record.\036  \037aa\037b\037c\036\037b0\036\035\000"
    rec = MARC::Record.new_from_marc(marc)
    expect { rec.to_marc }.not_to raise_error
  end

  it "handles Unicode roundtrip" do
    record = MARC::Reader.new("test/utf8.marc", external_encoding: "UTF-8").first

    writer = MARC::Writer.new("test/writer.dat")
    writer.write(record)
    writer.close

    read_back_record = MARC::Reader.new("test/writer.dat", external_encoding: "UTF-8").first

    # Make sure the one we wrote out then read in again
    # is the same as the one we read the first time
    expect(record).to eq(read_back_record)
  end
end
