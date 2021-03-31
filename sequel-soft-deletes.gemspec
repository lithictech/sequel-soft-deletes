# frozen_string_literal: true

require_relative "lib/sequel/plugins/soft-deletes"

Gem::Specification.new do |spec|
  spec.name          = "sequel-plugins-soft-deletes"
  spec.version       = Sequel::Plugins::SoftDeletes::VERSION
  spec.authors       = ["Natalie"]
  spec.email         = ["natalie@lithic.tech"]

  spec.summary       = "Gem for enabling plugins soft-delete"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_dependency("sequel")
  spec.add_development_dependency("rspec")

end
