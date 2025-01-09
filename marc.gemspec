require File.join(File.dirname(__FILE__), "lib/marc/version")

Gem::Specification.new do |s|
  s.name = "marc"
  s.version = MARC::VERSION
  s.author = "Ed Summers"
  s.email = "ehs@pobox.com"
  s.homepage = "https://github.com/ruby-marc/ruby-marc/"
  s.summary = "A ruby library for working with Machine Readable Cataloging"
  s.license = "MIT"
  s.required_ruby_version = ">= 2.2.0"
  s.authors = ["Kevin Clarke", "Bill Dueber", "William Groppe", "Jonathan Rochkind", "Ross Singer", "Ed Summers", "Chris Beer"]

  s.files = `git ls-files -z`.split("\x0")
  s.executables = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency "nokogiri", "~>1.0"

  s.add_development_dependency "rake", "~>13.0"
  s.add_development_dependency "test-unit", "~>3.0"
  s.add_development_dependency "standard", "~>1.0"
  s.add_development_dependency "warning", "~>1.5"
  s.add_development_dependency "xml-simple"

  s.add_dependency "rexml" # rexml was unbundled from the stdlib in ruby 3
end
