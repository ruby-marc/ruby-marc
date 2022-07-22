#!/usr/bin/env ruby

# usage: xml2marc.rb marc.xml > marc.dat

require "marc"

reader = MARC::XMLReader.new(ARGV.shift)
reader.each do |record|
  $stdout.write(record.to_marc)
end
