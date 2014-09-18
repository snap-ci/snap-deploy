# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'snap_deploy/version'

Gem::Specification.new do |spec|
  spec.name          = "snap_deploy"
  spec.version       = SnapDeploy::VERSION
  spec.authors       = ["Snap CI"]
  spec.email         = ["support@snap-ci.com"]
  spec.summary       = %q{Deploy your application in a Snap}
  spec.description   = %q{A simple rubygem to help continuously deploy your application}
  spec.homepage      = "https://snap-ci.com"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($\) + Dir["bundle/**/*"] - Dir["**/*.gem"] + Dir['bin/*'] - Dir["bundle/ruby/2.0.0/gems/*/{spec,test,specs,tests,examples,doc,doc-api,benchmarks,benchmark,feature,features}/**/*"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "fpm"
  spec.add_development_dependency "rake"
  spec.add_development_dependency 'ansi'
  spec.add_development_dependency "clamp"
  spec.add_development_dependency "aws-sdk"
end
