# froze n_string_literal: true

require_relative "lib/kamal_podman/version"

Gem::Specification.new do |spec|
  spec.name = "kamal_podman"
  spec.version = KamalPodman::VERSION
  spec.authors = [ "Matthew Croall" ]
  spec.email = [ "matthew.croall@icloud.com" ]

  spec.summary = "Extends Kamal to support Podman as the container manager"
  spec.homepage = "https://github.com/phoozle/kamal-podman"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*", "LICENSE.txt", "README.md"]
  spec.executables = %w[kamal]

  spec.add_dependency "kamal", "2.3.0"
  spec.add_dependency "zeitwerk", ">= 2.6.18", "< 3.0"
  spec.add_dependency "activesupport", ">= 7.0"

  spec.add_development_dependency "debug"
  spec.add_development_dependency "mocha"
  spec.add_development_dependency "railties"
  spec.add_development_dependency "pry"
end
