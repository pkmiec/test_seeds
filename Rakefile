# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "test_seeds"
  gem.homepage = "http://github.com/pkmiec/test_seeds"
  gem.license = "MIT"
  gem.summary = %Q{Test Seeds allow efficient usage of object factories (like Factory Girl) in tests. Instead of creating objects for similar scenarios in each test case, Test Seeds start a db transaction for each test file, creates all the common objects once, and then uses db savepoints for each test case.}
  gem.description = %Q{Test Seeds piggy backs on the transaction fixtures functionality. Test Seeds load fixtures into the database in the same way but then start a db transaction for the duration of the test file. Any objects for the common scenarios are then created and inserted into the database. Test Seeds then execute each test case within a context of a db savepoint (or nested db transactions). This allows test seeds to be inserted into the database once and then re-used for each test case that needs it.}
  gem.email = "pkmiec@gmail.com"
  gem.authors = ["Paul Kmiec"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test
