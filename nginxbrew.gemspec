# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'nginxbrew/version'

Gem::Specification.new do |spec|
  spec.name          = "nginxbrew"
  spec.version       = Nginxbrew::VERSION
  spec.authors       = ["takumakanari"]
  spec.email         = ["chemtrails.t@gmail.com"]
  spec.summary       = "Multi installation for nginx."
  spec.description   = "Nginxbrew is a tool for install multi-version of nginx/nginxopenresty into your local environment."
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   << "nginxbrew"
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
