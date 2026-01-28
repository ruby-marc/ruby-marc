require 'spec_helper'

RSpec.describe MARC::ControlField do
  it "formats a control field correctly" do
    control = MARC::ControlField.new("005", "foobarbaz")
    expect(control.to_s).to eq("005 foobarbaz")
  end

  it "rejects data field as control field" do
    field = MARC::DataField.new("007")
    expect(field.valid?).to be(false)
  end

  it "rejects alpha control field tags" do
    # can't have a field with a tag < 010
    field = MARC::ControlField.new("DDD")
    expect(field.valid?).to be(false)
  end

  it "supports adding custom control field tags" do
    MARC::ControlField.control_tags << "FMT"
    field = MARC::ControlField.new("FMT")
    expect(field.valid?).to be(true)
    field = MARC::DataField.new("FMT")
    expect(field.valid?).to be(false)
    MARC::ControlField.control_tags.delete("FMT")
    field = MARC::DataField.new("FMT")
    expect(field.valid?).to be(true)
    field = MARC::ControlField.new("FMT")
    expect(field.valid?).to be(false)
  end

  it "rejects control field with data field tag" do
    # can't have a control with a tag > 009
    f = MARC::ControlField.new("245")
    expect(f.valid?).to be(false)
  end

  it "compares control fields correctly" do
    f1 = MARC::ControlField.new("001", "foobarbaz")
    f2 = MARC::ControlField.new("001", "foobarbaz")
    expect(f1).to eq(f2)

    f3 = MARC::ControlField.new("001", "foobarbazqux")
    expect(f1).not_to eq(f3)
    f4 = MARC::ControlField.new("002", "foobarbaz")
    expect(f1).not_to eq(f4)

    expect(f1).not_to eq("001")
    expect(f2).not_to eq("foobarbaz")
  end
end
