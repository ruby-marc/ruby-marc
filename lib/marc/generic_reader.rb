# frozen_string_literal: true

class MARC::GenericReader

  include Enumerable

  attr_reader :record_class, :control_class, :data_class, :subfield_class

  # The constructor which you may pass either a path
  #
  #   reader = MARC::Reader.new('marc.dat')
  #
  # or, if it's more convenient a File object:
  #
  #   fh = File.new('marc.dat')
  #   reader = MARC::Reader.new(fh)
  #
  # or really any object that responds to read(n)
  #
  #   # marc is a string with a bunch of records in it
  #   reader = MARC::Reader.new(StringIO.new(marc))
  #
  # If your data have non-standard control fields in them
  # (e.g., Aleph's 'FMT') you need to add them specifically
  # to the MARC::ControlField.control_tags Set object
  #
  #   MARC::ControlField.control_tags << 'FMT'
  #
  def initialize(file, record_class: MARC::Record)
    @record_class = record_class

    if file.is_a?(String)
      raise ArgumentError.new("File '#{file}' can't be found") unless File.exist?(file)
      raise ArgumentError.new("File '#{file}' can't be opened for reading") unless File.readable?(file)
      @handle = File.new(file)
    elsif file.respond_to?(:read, 5)
      @handle = file
    else
      raise ArgumentError, "must pass in path or file, not `#{file.inspect}`"
    end
  end


end