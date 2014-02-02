# frozen_string_literal: true

require_relative "lib/philiprehberger/schema_validator/version"

Gem::Specification.new do |spec|
  spec.name = "philiprehberger-schema_validator"
  spec.version = Philiprehberger::SchemaValidator::VERSION
  spec.authors = ["Philip Rehberger"]
  spec.email = ["me@philiprehberger.com"]

  spec.summary = "Lightweight schema validation for hashes with type coercion"
  spec.description = "A zero-dependency Ruby gem for validating hash data against schemas " \
                     "with type checking, coercion, required/optional fields, and custom validators."
  spec.homepage = "https://github.com/philiprehberger/rb-schema-validator"
  spec.license = "MIT"

  spec.required_ruby_version = ">= 3.1"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir["lib/**/*.rb", "LICENSE", "README.md", "CHANGELOG.md"]
  spec.require_paths = ["lib"]
end
