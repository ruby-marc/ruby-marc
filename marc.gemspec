require 'rubygems'
spec = Gem::Specification.new do |s|
    s.name = 'marc'
    s.version = '0.0.9'
    s.author = 'Ed Summers'
    s.email = 'ehs@pobox.com'
    s.homepage = 'http://www.textualize.com/ruby_marc'
    s.platform = Gem::Platform::RUBY
    s.summary = 'A ruby library for working with Machine Readable Cataloging'
    s.files = Dir.glob("{lib,test}/**/*")
    s.require_path = 'lib'
    s.autorequire = 'marc'
    s.has_rdoc = true
    s.test_file = 'test/ts_marc.rb'
    s.bindir = 'bin'
end

if $0 == __FILE__
    Gem::manage_gems
    Gem::Builder.new(spec).build
end

