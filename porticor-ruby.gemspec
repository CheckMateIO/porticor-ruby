# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'porticor/version'

Gem::Specification.new do |spec|
  spec.name          = "porticor-ruby"
  spec.version       = Porticor::VERSION
  spec.authors       = ["Brian McManus"]
  spec.email         = ["brian@checkmate.io"]
  spec.summary       = %q{API wrapper for Porticor cloud security.}
  spec.homepage      = "https://github.com/CheckMateIO/porticor-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'webmock', '~> 1.15'
  spec.add_development_dependency 'vcr', '~> 2.8.0'

  spec.add_runtime_dependency 'hashie', '~> 2.1.1'
  spec.add_runtime_dependency 'faraday', '~> 0.9.0'
  spec.add_runtime_dependency 'faraday_middleware'
end
