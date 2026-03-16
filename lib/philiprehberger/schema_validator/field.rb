# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class Field
      attr_reader :name, :type, :default, :validator, :format, :in, :min, :max

      def initialize(name, type, required: true, default: nil, format: nil, in: nil, min: nil, max: nil, &validator) # rubocop:disable Metrics/ParameterLists
        @name = name
        @type = type
        @required = required
        @default = default
        @format = format
        @in = binding.local_variable_get(:in)
        @min = min
        @max = max
        @validator = validator
      end

      def required?
        @required
      end
    end
  end
end
