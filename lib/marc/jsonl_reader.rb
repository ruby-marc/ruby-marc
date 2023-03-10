# frozen_string_literal: true

require_relative "generic_reader"
require "json"

module MARC
  # Read marc-in-json documents from a `.jsonl` file -- also called
  # "newline-delimited JSON", which is a file with one JSON document on each line.
  class JSONLReader < GenericReader
    # Turn marc-in-json lines into actual marc records and yield them
    # @yieldreturn [MARC::Record] record created from each line of the file
    def each
      return enum_for(:each) unless block_given?
      @handle.each do |line|
        yield record_class.new_from_hash(JSON.parse(line))
      end
    end
  end
end
