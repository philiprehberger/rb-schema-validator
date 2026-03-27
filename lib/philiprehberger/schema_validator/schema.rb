# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class ValidationError < StandardError; end

    class Schema
      include Constraints

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

      def nested(name, **opts, &)
        sub_schema = Schema.new(&)
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
        raise ValidationError, result.errors.join(', ') unless result.valid?

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

        return errors << "#{name} must be a hash" unless value.is_a?(Hash)

        collect_nested_errors(name, config[:schema], value, errors)
      end

      def collect_nested_errors(name, schema, value, errors)
        schema.validate(value).errors.each { |err| errors << "#{name}.#{err}" }
      end
    end
  end
end
