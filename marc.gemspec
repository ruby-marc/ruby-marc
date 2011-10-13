# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "marc/version"

spec = Gem::Specification.new do |s|
  s.name          = 'marc'
  s.version       = Marc::VERSION
  s.author        = 'Ed Summers'
  s.email         = 'ehs@pobox.com'
  s.homepage      = 'http://marc.rubyforge.org/'
  s.platform      = Gem::Platform::RUBY
  s.summary       = 'A ruby library for working with Machine Readable Cataloging'
  s.files         = Dir.glob("{lib,test}/**/*") + ["Rakefile", "README", "Changes", "LICENSE"]
  s.require_path  = 'lib'
  s.autorequire   = 'marc'
  s.has_rdoc      = true
  s.required_ruby_version = '>= 1.8.6'
  s.authors       = ["Kevin Clarke", "Bill Dueber", "William Groppe", "Ross Singer", "Ed Summers"]
  s.test_file     = 'test/ts_marc.rb'
  s.bindir        = 'bin'
end

