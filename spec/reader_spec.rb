require 'spec_helper'

RSpec.describe MARC::Reader do
  it "reads batch records correctly" do
    reader = MARC::Reader.new("test/batch.dat")
    count = 0
    reader.each { count += 1 }
    expect(count).to eq(10)
  end

  it "handles loose records with ForgivingReader" do
    reader = MARC::ForgivingReader.new("test/batch.dat")
    count = 0
    reader.each { count += 1 }
    expect(count).to eq(10)
  end

  it "handles UTF-8 in ForgivingReader" do
    # This isn't actually a corrupt file, but it is utf8,
    # and I have some reason to believe forgiving reader isn't
    # working properly with UTF8 in ruby 1.9, so testing it.
    reader = MARC::ForgivingReader.new("test/utf8.marc")
    count = 0
    reader.each { count += 1 }
    expect(count).to eq(1)
  end

  it "handles unimarc records" do
    # Unimarc might use a different record seperator? Let's make sure it works.
    reader = MARC::Reader.new(File.open("test/cp866_unimarc.marc", "r:cp866"))
    count = 0
    reader.each { |a| count += 1 }
    expect(count).to eq(1)
  end

  it "handles non-numeric tags" do
    reader = MARC::Reader.new("test/non-numeric.dat")
    count = 0
    record = nil
    reader.each do |rec|
      count += 1
      record = rec
    end
    expect(count).to eq(1)
    expect(record["ISB"]["a"]).to eq("9780061317842")
    expect(record["LOC"]["9"]).to eq("1")
  end

  it "raises exception for bad MARC data" do
    reader = MARC::Reader.new("test/tc_reader.rb")
    expect { reader.entries[0] }.to raise_error(MARC::Exception)
  end

  it "supports search functionality" do
    reader = MARC::Reader.new("test/batch.dat")
    records = reader.find_all { |r| r =~ /Perl/ }
    expect(records.length).to eq(10)

    reader = MARC::Reader.new("test/batch.dat")
    records = reader.find_all { |r| r["245"] =~ /Perl/ }
    expect(records.length).to eq(10)

    reader = MARC::Reader.new("test/batch.dat")
    records = reader.find_all { |r| r["245"]["a"] =~ /Perl/ }
    expect(records.length).to eq(10)

    reader = MARC::Reader.new("test/batch.dat")
    records = reader.find_all { |r| r =~ /Foo/ }
    expect(records.length).to eq(0)
  end

  it "provides a binary enumerator" do
    reader = MARC::Reader.new("test/batch.dat")
    iter = reader.each
    r = iter.next
    expect(r).to be_an_instance_of(MARC::Record)
    9.times { iter.next } # total of ten records
    expect { iter.next }.to raise_error(StopIteration)
  end

  it "supports each_raw method" do
    reader = MARC::Reader.new("test/batch.dat")
    count = 0
    raw = nil
    reader.each_raw { |r|
      count += 1
      raw = r
    }
    expect(count).to eq(10)
    expect(raw).to be_an_instance_of(String)

    record = MARC::Reader.decode(raw)
    expect(record).to be_an_instance_of(MARC::Record)
  end

  it "supports each_raw enumerator" do
    reader = MARC::Reader.new("test/batch.dat")
    enum = reader.each_raw
    r = enum.next
    expect(r).to be_an_instance_of(String)

    record = MARC::Reader.decode(r)
    expect(record).to be_an_instance_of(MARC::Record)

    9.times { enum.next } # total of ten records
    expect { enum.next }.to raise_error(StopIteration)
  end
end
