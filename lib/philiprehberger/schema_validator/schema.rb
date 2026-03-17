# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class ValidationError < StandardError; end

    class Schema
      TYPES = %i[string integer float boolean array hash].freeze

      def initialize(&block)
        @fields = {}
        @nested_schemas = {}
        @cross_validators = []
        instance_eval(&block) if block
      end

      TYPES.each do |type|
        method_name = type == :hash ? :hash_field : type
        define_method(method_name) do |name, **opts, &validator|
          @fields[name] = Field.new(name, type, **opts, &validator)
        end
      end

      def nested(name, **opts, &block)
        sub_schema = Schema.new(&block)
        @nested_schemas[name] = { schema: sub_schema, required: opts.fetch(:required, false) }
      end

      def validate(data = nil, &block)
        if block
          @cross_validators << block
          return
        end

        errors = []
        @fields.each_value { |field| validate_field(field, data, errors) }
        @nested_schemas.each { |name, config| validate_nested(name, config, data, errors) }
        @cross_validators.each { |cv| cv.call(data, errors) }
        Result.new(errors: errors)
      end

      def validate!(data)
        result = validate(data)
        raise ValidationError, result.errors.join(", ") unless result.valid?

        result
      end

      def fields
        @fields.keys
      end

      def merge(&block)
        new_schema = Schema.new
        new_schema.instance_variable_set(:@fields, @fields.dup)
        new_schema.instance_variable_set(:@nested_schemas, @nested_schemas.dup)
        new_schema.instance_variable_set(:@cross_validators, @cross_validators.dup)
        new_schema.instance_eval(&block) if block
        new_schema
      end

      private

      def validate_field(field, data, errors)
        value = fetch_value(field, data)
        field_label = field.name.to_s

        if value.nil?
          errors << "#{field_label} is required" if field.required?
          return
        end

        check_type(field, value, errors, field_label)
      end

      def fetch_value(field, data)
        return data[field.name] if data.key?(field.name)

        field.default
      end

      def validate_nested(name, config, data, errors)
        value = data[name]

        if value.nil?
          errors << "#{name} is required" if config[:required]
          return
        end

        unless value.is_a?(Hash)
          errors << "#{name} must be a hash"
          return
        end

        sub_result = config[:schema].validate(value)
        sub_result.errors.each do |err|
          errors << "#{name}.#{err}"
        end
      end

      def check_type(field, value, errors, field_label)
        coerced = Coercer.coerce(value, field.type)
        if coerced.nil?
          errors << "#{field_label} must be #{field.type}"
        else
          check_constraints(field, coerced, errors, field_label)
        end
      end

      def check_constraints(field, value, errors, field_label)
        check_format(field, value, errors, field_label)
        check_inclusion(field, value, errors, field_label)
        check_range(field, value, errors, field_label)
        check_array_elements(field, value, errors, field_label)
        run_custom_validator(field, value, errors, field_label)
      end

      def check_format(field, value, errors, field_label)
        return unless field.format

        pattern = resolve_format(field.format)
        errors << "#{field_label} does not match expected format" unless value.match?(pattern)
      end

      def resolve_format(fmt)
        return fmt if fmt.is_a?(Regexp)

        Formats::FORMATS.fetch(fmt) do
          raise ArgumentError, "unknown format preset: #{fmt}"
        end
      end

      def check_inclusion(field, value, errors, field_label)
        return unless field.in

        errors << "#{field_label} must be one of: #{field.in.join(', ')}" unless field.in.include?(value)
      end

      def check_range(field, value, errors, field_label)
        errors << "#{field_label} must be >= #{field.min}" if field.min && value < field.min
        errors << "#{field_label} must be <= #{field.max}" if field.max && value > field.max
      end

      def check_array_elements(field, value, errors, field_label)
        return unless field.type == :array && value.is_a?(Array)

        if field.of
          validate_array_of_type(field, value, errors, field_label)
        elsif field.schema
          validate_array_of_schema(field, value, errors, field_label)
        end
      end

      def validate_array_of_type(field, value, errors, field_label)
        value.each_with_index do |elem, idx|
          coerced = Coercer.coerce(elem, field.of)
          errors << "#{field_label}[#{idx}] must be a #{field.of}" if coerced.nil?
        end
      end

      def validate_array_of_schema(field, value, errors, field_label)
        value.each_with_index do |elem, idx|
          unless elem.is_a?(Hash)
            errors << "#{field_label}[#{idx}] must be a hash"
            next
          end

          sub_result = field.schema.validate(elem)
          sub_result.errors.each do |err|
            errors << "#{field_label}[#{idx}].#{err}"
          end
        end
      end

      def run_custom_validator(field, value, errors, field_label)
        return unless field.validator

        msg = field.validator.call(value)
        errors << "#{field_label} #{msg}" if msg.is_a?(String)
      end
    end
  end
end
