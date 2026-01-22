require 'spec_helper'

RSpec.describe MARC::DataField do
  it "handles tags correctly" do
    f1 = MARC::DataField.new("100")
    expect(f1.tag).to eq("100")
    f2 = MARC::DataField.new("100")
    expect(f2.tag).to eq("100")
    expect(f1).to eq(f2)
    f3 = MARC::DataField.new("245")
    expect(f1).not_to eq(f3)
  end

  it "handles alphabetic tags" do
    alph = MARC::DataField.new("ALF")
    expect(alph.tag).to eq("ALF")

    alphnum = MARC::DataField.new("0D9")
    expect(alphnum.tag).to eq("0D9")
  end

  it "handles indicators" do
    f1 = MARC::DataField.new("100", "0", "1")
    expect(f1.indicator1).to eq("0")
    expect(f1.indicator2).to eq("1")
    f2 = MARC::DataField.new("100", "0", "1")
    expect(f2.indicator1).to eq("0")
    expect(f2.indicator2).to eq("1")
    expect(f1).to eq(f2)
    f3 = MARC::DataField.new("100", "1", "1")
    expect(f1).not_to eq(f3)
  end

  it "handles subfields" do
    f1 = MARC::DataField.new("100", "0", "1",
      MARC::Subfield.new("a", "Foo"),
      MARC::Subfield.new("b", "Bar"))
    expect(f1.to_s).to eq("100 01 $a Foo $b Bar ")
    expect(f1.value).to eq("FooBar")
    f2 = MARC::DataField.new("100", "0", "1",
      MARC::Subfield.new("a", "Foo"),
      MARC::Subfield.new("b", "Bar"))
    expect(f1).to eq(f2)
    f3 = MARC::DataField.new("100", "0", "1",
      MARC::Subfield.new("a", "Foo"),
      MARC::Subfield.new("b", "Bez"))
    expect(f1).not_to eq(f3)
  end

  it "supports subfield shorthand" do
    f = MARC::DataField.new("100", "0", "1", ["a", "Foo"], ["b", "Bar"])
    expect(f.to_s).to eq("100 01 $a Foo $b Bar ")
  end

  it "iterates through subfields" do
    field = MARC::DataField.new("100", "0", "1", ["a", "Foo"], ["b", "Bar"],
      ["a", "Bez"])
    count = 0
    field.each { |x| count += 1 }
    expect(count).to eq(3)
  end

  it "supports lookup shorthand" do
    f = MARC::DataField.new("100", "0", "1", ["a", "Foo"], ["b", "Bar"])
    expect(f["b"]).to eq("Bar")
  end

  it "distinguishes from other types" do
    f = MARC::DataField.new("100", "0", "1",
      MARC::Subfield.new("a", "Foo"),
      MARC::Subfield.new("b", "Bar"))
    expect(f).not_to eq("100 01 $a Foo $b Bar ")
    expect(f).not_to eq(f["a"])
  end
end
