# frozen_string_literal: true

require_relative "schema_validator/version"
require_relative "schema_validator/field"
require_relative "schema_validator/result"
require_relative "schema_validator/coercer"
require_relative "schema_validator/formats"
require_relative "schema_validator/constraints"
require_relative "schema_validator/schema"

module Philiprehberger
  module SchemaValidator
    def self.define(&)
      Schema.new(&)
    end
  end
end
