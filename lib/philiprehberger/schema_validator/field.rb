# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class Field
      attr_reader :name, :type, :default, :validator, :format, :in, :min, :max, :of, :schema

      def initialize(name, type, required: true, default: nil, format: nil, in: nil, min: nil, max: nil, of: nil, schema: nil, &validator) # rubocop:disable Metrics/ParameterLists,Layout/LineLength
        assign_basic_attrs(name, type, required, default, format)
        assign_constraint_attrs(binding.local_variable_get(:in), min, max, of, schema)
        @validator = validator
      end

      def required?
        @required
      end

      private

      def assign_basic_attrs(name, type, required, default, format)
        @name = name
        @type = type
        @required = required
        @default = default
        @format = format
      end

      def assign_constraint_attrs(inclusion, min, max, of, schema)
        @in = inclusion
        @min = min
        @max = max
        @of = of
        @schema = schema
      end
    end
  end
end
