# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pippa/version'

Gem::Specification.new do |spec|
  spec.name          = "pippa"
  spec.version       = Pippa::VERSION
  spec.authors       = ["Gene Ressler"]
  spec.email         = ["gene.ressler@gmail.com"]
  spec.description   = %q{Draw marks on maps by lat/lon or zip code.}
  spec.summary       = %q{Port of the plot-latlon utility from CAIDA (http://www.caida.org).}
  spec.homepage      = "http://sourceforge.net/projects/pippa"
  spec.license       = "GPL3"

  spec.files         = `git ls-files`.split($/) +
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency "gd2"
end
