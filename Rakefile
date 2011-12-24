require './version.rb'
require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

task :default => [:test]

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.pattern = 'test/tc_*.rb'
  t.verbose = true
  t.ruby_opts = ['-r marc', '-r test/unit']
end

Rake::GemPackageTask.new(Version::SPEC) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new('doc') do |rd|
  rd.rdoc_files.include("README", "Changes", "LICENSE", "lib/**/*.rb")
  rd.main = 'MARC::Record'
  rd.rdoc_dir = 'doc'
end
