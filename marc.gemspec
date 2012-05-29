# -*- encoding: utf-8 -*-

require File.expand_path('../lib/marc/version', __FILE__)

Gem::Specification.new do |gem|
  gem.name          = "marc"
  gem.version       = MARC::VERSION
  
  gem.author        = 'Ed Summers'
  gem.email         = 'ehs@pobox.com'
  gem.homepage      = 'https://github.com/ruby-marc/ruby-marc/'
  gem.platform      = Gem::Platform::RUBY
  gem.summary       = 'A ruby library for working with Machine Readable Cataloging'
  gem.require_path  = 'lib'
  gem.autorequire   = 'marc'
  gem.has_rdoc      = true
  gem.required_ruby_version = '>= 1.8.6'
  gem.authors       = ["Kevin Clarke", "Bill Dueber", "William Groppe", "Ross Singer", "Ed Summers"]
  gem.bindir        = 'bin'
  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
