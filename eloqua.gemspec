$:.push File.expand_path("../lib", __FILE__)
require "eloqua/version"

Gem::Specification.new do |s|
  s.name = 'eloqua'
  s.version = Eloqua::VERSION
  s.date = '2012-08-14'
  s.authors = ["Brian Jou", "Ryan Caught", "James Lal"]
  s.email = 'brian@vidyard.com'
  s.files = ["lib/eloqua.rb"]
  s.summary = 'Eloqua API for Ruby'
  s.description = 'An Eloqua API Wrapper for Ruby'
  s.homepage = 'https://github.com/Vidyard/eloqua'

  s.add_runtime_dependency 'savon', '~> 1.0'
  s.add_runtime_dependency 'builder'
  s.add_runtime_dependency 'activemodel'
  s.add_runtime_dependency 'activesupport', '>= 3.0.6'
  s.add_runtime_dependency 'i18n', '>= 0.5.0'
  s.add_development_dependency 'watchr'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'ruby-fsevent'
  s.add_development_dependency 'savon_spec'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'flexmock'
  s.add_development_dependency 'timecop'
  s.add_development_dependency 'ci_reporter'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
