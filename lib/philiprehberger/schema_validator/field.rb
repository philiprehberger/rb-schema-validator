# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class Field
      attr_reader :name, :type, :default, :validator

      def initialize(name, type, required: true, default: nil, &validator)
        @name = name
        @type = type
        @required = required
        @default = default
        @validator = validator
      end

      def required?
        @required
      end
    end
  end
end
