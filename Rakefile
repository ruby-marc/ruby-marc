require 'rubygems'

require 'rake'
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

require 'minitest/autorun'

task :default => [:test]

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/tc_*.rb'
  t.verbose = true
end


Rake::RDocTask.new('doc') do |rd|
  rd.rdoc_files.include("README", "Changes", "LICENSE", "lib/**/*.rb")
  rd.main = 'MARC::Record'
  rd.rdoc_dir = 'doc'
end
