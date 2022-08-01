# frozen_string_literal: true

require "json"

module MARC
  # Read marc-in-json documents from a `.jsonl` file -- also called
  # "newline-delimited JSON", which is a file with one JSON document on each line.
  class JSONLReader
    include Enumerable

    # @param [String, IO] file A filename, or open File/IO type object, from which to read
    def initialize(file)
      if file.is_a?(String)
        raise ArgumentError.new("File '#{file}' can't be found") unless File.exist?(file)
        raise ArgumentError.new("File '#{file}' can't be opened for reading") unless File.readable?(file)
        @handle = File.new(file)
      elsif file.respond_to?(:read, 5)
        @handle = file
      else
        raise ArgumentError, "must pass in path or file"
      end
    end

    # Turn marc-in-json lines into actual marc records and yield them
    # @yieldreturn [MARC::Record] record created from each line of the file
    def each
      return enum_for(:each) unless block_given?
      @handle.each do |line|
        yield MARC::Record.new_from_hash(JSON.parse(line))
      end
    end
  end
end
