# frozen_string_literal: true

require_relative "lib/sequel/plugins/soft_deletes"

Gem::Specification.new do |spec|
  spec.name          = "sequel-plugins-soft-deletes"
  spec.version       = Sequel::Plugins::SoftDeletes::VERSION
  spec.authors       = ["Lithic Tech"]
  spec.email         = ["hello@lithic.tech"]

  spec.summary       = "Gem for enabling soft-deletion in tables"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_development_dependency "activesupport"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rubocop-performance"
  spec.add_development_dependency "rubocop-rake"
  spec.add_development_dependency "rubocop-rspec"
  spec.add_development_dependency "rubocop-sequel"
  spec.add_development_dependency "sequel"
  spec.add_dependency "sqlite3"
end
