# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class ValidationError < StandardError; end

    class Schema
      TYPES = %i[string integer float boolean array hash].freeze

      def initialize(&block)
        @fields = {}
        instance_eval(&block) if block
      end

      TYPES.each do |type|
        method_name = type == :hash ? :hash_field : type
        define_method(method_name) do |name, **opts, &validator|
          @fields[name] = Field.new(name, type, **opts, &validator)
        end
      end

      def validate(data)
        errors = []
        @fields.each_value { |field| validate_field(field, data, errors) }
        Result.new(errors: errors)
      end

      def validate!(data)
        result = validate(data)
        raise ValidationError, result.errors.join(", ") unless result.valid?

        result
      end

      private

      def validate_field(field, data, errors)
        value = fetch_value(field, data)
        return check_required(field, errors) if value.nil?

        check_type(field, value, errors)
      end

      def fetch_value(field, data)
        return data[field.name] if data.key?(field.name)

        field.default
      end

      def check_required(field, errors)
        errors << "#{field.name} is required" if field.required?
      end

      def check_type(field, value, errors)
        coerced = Coercer.coerce(value, field.type)
        if coerced.nil?
          errors << "#{field.name} must be #{field.type}"
        else
          run_custom_validator(field, coerced, errors)
        end
      end

      def run_custom_validator(field, value, errors)
        return unless field.validator

        msg = field.validator.call(value)
        errors << "#{field.name} #{msg}" if msg.is_a?(String)
      end
    end
  end
end
