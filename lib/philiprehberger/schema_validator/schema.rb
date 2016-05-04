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

      def fields
        @fields.keys
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
          check_constraints(field, coerced, errors)
        end
      end

      def check_constraints(field, value, errors)
        check_format(field, value, errors)
        check_inclusion(field, value, errors)
        check_range(field, value, errors)
        run_custom_validator(field, value, errors)
      end

      def check_format(field, value, errors)
        return unless field.format

        errors << "#{field.name} does not match expected format" unless value.match?(field.format)
      end

      def check_inclusion(field, value, errors)
        return unless field.in

        errors << "#{field.name} must be one of: #{field.in.join(', ')}" unless field.in.include?(value)
      end

      def check_range(field, value, errors)
        errors << "#{field.name} must be >= #{field.min}" if field.min && value < field.min
        errors << "#{field.name} must be <= #{field.max}" if field.max && value > field.max
      end

      def run_custom_validator(field, value, errors)
        return unless field.validator

        msg = field.validator.call(value)
        errors << "#{field.name} #{msg}" if msg.is_a?(String)
      end
    end
  end
end
