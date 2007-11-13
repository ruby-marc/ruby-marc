#!/usr/bin/env ruby

# usage: xml2marc.rb marc.xml > marc.dat

require 'rubygems'
require 'marc'

reader = MARC::XMLReader.new(ARGV.shift)
for record in reader:
  STDOUT.write(record.to_marc)
end

