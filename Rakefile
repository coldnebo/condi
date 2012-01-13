require 'rubygems/package_task'
require 'rake/testtask'
require 'yard'


PKG_VERSION = '0.0.5'

SRC_FILES = Dir.glob('lib/**/*')
TST_FILES = Dir.glob('test/**/*')
EXTRA_DOC_FILES = ["README.md", "MIT-LICENSE"]


PKG_FILES = [SRC_FILES, EXTRA_DOC_FILES].flatten

spec = Gem::Specification.new do |s|
  s.platform = Gem::Platform::RUBY

  s.version = PKG_VERSION
  s.requirements << 'rails'
  #s.add_dependency('rails')  
  s.require_path = 'lib'
  
  s.files       = PKG_FILES
  s.test_files  = TST_FILES
  s.description = "Conditional UI predicates for Rails"

  s.name        = 'condi'
  s.date        = '2011-12-14'
  s.summary     = "Condi"
  s.authors     = ["Larry Kyrala"]
  s.email       = 'larry.kyrala@gmail.com'
  s.homepage    = 'http://github.com/coldnebo/condi'
  s.has_rdoc    = 'yard'
  
end

Gem::PackageTask.new(spec) do |pkg|
end

YARD::Rake::YardocTask.new do |t|
  t.files   = [SRC_FILES, '-', EXTRA_DOC_FILES].flatten   # optional
end

Rake::TestTask.new do |t|
  t.libs << 'test'
end

desc "Run tests"
task :default => :test
