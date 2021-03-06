# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ecs/easy/cluster/version'

Gem::Specification.new do |spec|
  spec.name          = "ecs-easy-cluster"
  spec.version       = Ecs::Easy::Cluster::VERSION
  spec.authors       = ["metheglin"]
  spec.email         = ["pigmybank@gmail.com"]
  spec.summary       = %q{easy-to-use AWS ECS Cluster.}
  spec.description   = %q{easy-to-use AWS ECS Cluster.}
  spec.homepage      = "https://github.com/metheglin/ecs-easy-cluster"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "aws-sdk", "~> 2.4"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
