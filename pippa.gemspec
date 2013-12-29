# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pippa/version'

Gem::Specification.new do |spec|
  spec.name          = "pippa"
  spec.version       = Pippa::VERSION
  spec.authors       = ["Gene Ressler"]
  spec.email         = ["gene.ressler@gmail.com"]
  spec.description   = %q{Draw dots on maps by lat/lon or zip code.}
  spec.summary       = %q{Port of the plot-latlon utility from CAIDA (http://www.caida.org).}
  spec.homepage      = "https://github.com/gene-ressler/pippa/wiki"
  spec.license       = "GPLv3"

  spec.files         = `git ls-files`.split($/) +
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  # Make work on earlier versions, but this is where testing has been performed.
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "ruby-prof", "~> 0.13"
  spec.add_runtime_dependency "rmagick", "~> 2.13"
end
