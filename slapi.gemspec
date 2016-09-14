# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbconfig'

Gem::Specification.new do |spec|
  spec.name          = 'slapi'
  spec.version       = '0.0.1.alpha'
  spec.authors       = ['Levi Smith', 'Aaron Blyth']
  spec.email         = ['atat@hearst.com']

  spec.summary       = 'SLAPI Bot, Your Gateway to ChatOps'
  spec.description   = 'Simple Lightweight API Bot (SLAPI), A bot for every language'
  spec.homepage      = 'https://github.com/imperiallabs/slapi'

  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rake', '~> 10.5'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_dependency 'rest-client', '~> 1.8'
end
