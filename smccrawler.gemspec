lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'smccrawler/version'

Gem::Specification.new do |spec|
  spec.name = 'smccrawler'
  spec.version = Clovercrawler::VERSION
  spec.summary = 'Import data from smc.'
  spec.authors = ['Daria Evdokimova']
  spec.email = %w(dariaevdo@gmail.com)

  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'awesome_print'
  spec.add_development_dependency 'pry'

  spec.add_dependency 'watir'
  spec.add_dependency 'watir-webdriver'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'zip-zip'

  spec.license = 'Private'
end