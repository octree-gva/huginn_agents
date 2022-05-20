# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "huginn_harvest"
  spec.version       = "0.0.1"
  spec.authors       = ["Hadrien Froger"]
  spec.email         = ["hadrien@octree.ch"]

  spec.summary       = "Harvest tasks for Huginn"
  spec.description   = "Fetch resources from harvest."

  spec.homepage      = "https://github.com/octree-gva/huginn_agents"


  spec.files         = Dir["LICENSE.txt", "lib/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = Dir["spec/**/*.rb"].reject { |f| f[%r{^spec/huginn}] }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency "huginn_agent"
  spec.add_runtime_dependency "harvesting"
end
