# coding: utf-8
# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbconfig'

Gem::Specification.new do |spec|
  spec.name          = 'slapi'
  spec.version       = '0.2.1'
  spec.authors       = ['Levi Smith', 'Aaron Blythe']
  spec.email         = ['atat@hearst.com']

  spec.summary       = 'SLAPI Bot, Your Gateway to ChatOps'
  spec.description   = 'Simple Lightweight API Bot (SLAPI), A bot for every language'
  spec.homepage      = 'https://github.com/imperiallabs/slapi'

  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'docker-api', '~> 1.33.0'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'redis'
  spec.add_dependency 'sinatra-contrib'
  spec.add_dependency 'slack-ruby-client'
  spec.add_dependency 'httparty'
  spec.add_dependency 'sterile'

  spec.add_development_dependency 'codeclimate-test-reporter', '~> 1.0'
  spec.add_development_dependency 'github_changelog_generator', '~> 1.14.1'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'factory_girl', '~> 4.0'
  spec.add_development_dependency 'fuubar'
  spec.add_development_dependency 'rspec', '~> 3.6'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'debase', '~> 0.2.2.beta10'
  spec.add_development_dependency 'ruby-debug-ide', '~> 0.6.1.beta4'
  spec.add_development_dependency 'rack-test'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'simplecov'
end
