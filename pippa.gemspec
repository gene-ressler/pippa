# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pippa/version'

Gem::Specification.new do |spec|
  spec.name          = "pippa"
  spec.version       = Pippa::VERSION
  spec.authors       = ["Gene Ressler"]
  spec.email         = ["gene.ressler@gmail.com"]

  spec.summary       = %q{Reimplements some parts of the plot-latlon utility from CAIDA (http://www.caida.org).}
  spec.description   =
%q{Draw dots on maps by lat/lon or zip code. Includes a library of 30 map backgrounds,
and associated geocoding configuration data, and a table of US zip codes with their
approximate centroids as latitude and longitude. Exposes the ImageMagick image and
coordinate conversions so that overlaying labels, lines, and other features on dots
is possible. Renders as a blob suitable for e.g. Rails send_data as an img tag src
and writes files in any supported ImageMagick graphic format.}

  spec.homepage      = "https://github.com/gene-ressler/pippa/wiki"
  spec.licenses      = ["GPL-3.0", "RUC"]

  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  # Make work on earlier versions, but this is where testing has been performed.
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 10.1"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "ruby-prof", "~> 0.13"
  spec.add_runtime_dependency "rmagick", "~> 2.13"
end
