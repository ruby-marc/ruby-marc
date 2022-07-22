# frozen_string_literal: true

require "json"
require "marc/writer"

module MARC
  class JSONLWriter < MARC::Writer
    # @param [String, IO] file A filename, or open File/IO type object, from which to read
    def initialize(file)
      if file.instance_of?(String)
        @fh = File.new(file, "w:utf-8")
      elsif file.respond_to?(:write)
        @fh = file
      else
        raise ArgumentError, "must pass in file name or handle"
      end
    end

    # Write encoded record to the handle
    # @param [MARC::Record] record
    # @return [MARC::JSONLWriter] self
    def write(record)
      @fh.puts(encode(record))
      self
    end

    # Encode the record as a marc-in-json string
    # @param [MARC::Record] record
    # @return [String] MARC-in-JSON representation of the record
    def self.encode(record)
      JSON.fast_generate(record.to_hash)
    end

    # @see MARC::JSONLWriter.encode
    def encode(rec)
      self.class.encode(rec)
    end
  end
end
