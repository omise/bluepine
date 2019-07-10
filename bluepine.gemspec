
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "bluepine/version"

Gem::Specification.new do |s|
  s.name          = "bluepine"
  s.version       = Bluepine::VERSION
  s.authors       = ["Marut K"]
  s.email         = ["marut@omise.co"]

  s.summary       = %q{A DSL for defining API schemas/endpoints}
  s.description   = %q{A DSL for defining API schemas/endpoints, validating, serializing and generating Open API v3}
  s.homepage      = "https://github.com/omise/bluepine"
  s.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  s.files         = `git ls-files -z lib`.split("\x0")
  s.require_paths = ["lib"]
  s.required_ruby_version = '>= 2.0.0'
  s.extra_rdoc_files = [ "README.md" ]

  s.add_dependency "activesupport", "~> 5.0"
  s.add_dependency "activemodel", "~> 5.0"

  s.add_development_dependency "bundler", "~> 1.17"
  s.add_development_dependency "rake", "~> 10.0"
  s.add_development_dependency "minitest", "~> 5.0"
  s.add_development_dependency "mocha", "~> 1.8"
  s.add_development_dependency "simplecov", "~> 0.16"
  s.add_development_dependency "actionpack", "~> 5.0"
  s.add_development_dependency "rubocop", "~> 0.71.0"
end
