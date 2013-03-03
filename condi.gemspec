# -*- encoding: utf-8 -*-
require File.expand_path('../lib/condi/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Larry Kyrala"]
  gem.email         = ["larry.kyrala@gmail.com"]
  gem.description   = %q{Conditional UI predicates for Rails - a clean and simple approach to separate business logic from your views and models.}
  gem.summary       = %q{Lightweight rules engine for Rails}
  gem.homepage      = "https://github.com/coldnebo/condi"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "condi"
  gem.require_paths = ["lib"]
  gem.version       = Condi::VERSION

  gem.add_dependency 'actionpack'

  gem.add_development_dependency 'mocha'
  gem.add_development_dependency 'pry'
  gem.add_development_dependency 'yard'
  gem.add_development_dependency 'redcarpet'
  gem.add_development_dependency 'simplecov'

end
