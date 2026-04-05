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

      # Declare a conditional field dependency
      #
      # @param field [Symbol] the field that becomes required
      # @param when_field [Hash] condition: { field_name => expected_value }
      def depends_on(field, when_field:)
        (@dependencies ||= []) << { field: field, when_field: when_field }
      end

      # Declare mutually exclusive fields
      #
      # @param name [Symbol] group name
      # @param fields [Array<Symbol>] fields that are mutually exclusive
      def exclusive_group(name, fields)
        (@exclusive_groups ||= []) << { name: name, fields: fields }
      end

      # Create a sub-schema with only the specified fields
      #
      # @param base [Schema] the base schema
      # @param field_names [Array<Symbol>] fields to include
      # @return [Schema] new schema with only selected fields
      def self.pick(base, *field_names)
        new_schema = new {} # rubocop:disable Lint/EmptyBlock
        base.instance_variable_get(:@fields).each do |name, field|
          new_schema.instance_variable_get(:@fields)[name] = field if field_names.include?(name)
        end
        new_schema
      end

      # Create a sub-schema excluding the specified fields
      #
      # @param base [Schema] the base schema
      # @param field_names [Array<Symbol>] fields to exclude
      # @return [Schema] new schema without excluded fields
      def self.omit(base, *field_names)
        new_schema = new {} # rubocop:disable Lint/EmptyBlock
        base.instance_variable_get(:@fields).each do |name, field|
          new_schema.instance_variable_get(:@fields)[name] = field unless field_names.include?(name)
        end
        new_schema
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
        result = Result.new(errors: errors)
        validate_dependencies(data, result) if @dependencies&.any?
        validate_exclusive_groups(data, result) if @exclusive_groups&.any?
        result
      end

      def validate!(data)
        result = validate(data)
        raise ValidationError, result.errors.join(', ') unless result.valid?

        result
      end

      def fields
        @fields.keys
      end

      # Export a simplified JSON Schema (draft 7) representation
      #
      # @return [Hash] a hash compatible with JSON Schema draft 7
      def to_json_schema
        properties = {}
        required_fields = []

        @fields.each do |name, field|
          properties[name.to_s] = field_to_json_schema(field)
          required_fields << name.to_s if field.required?
        end

        @nested_schemas.each do |name, config|
          properties[name.to_s] = config[:schema].to_json_schema
          required_fields << name.to_s if config[:required]
        end

        schema = {
          'type' => 'object',
          'properties' => properties
        }
        schema['required'] = required_fields unless required_fields.empty?
        schema
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

      TYPE_MAP = {
        string: 'string',
        integer: 'integer',
        float: 'number',
        boolean: 'boolean',
        array: 'array',
        hash: 'object'
      }.freeze

      def field_to_json_schema(field)
        prop = { 'type' => TYPE_MAP.fetch(field.type, field.type.to_s) }
        prop['default'] = field.default unless field.default.nil?
        prop['enum'] = field.in.dup if field.in
        prop['minimum'] = field.min if field.min
        prop['maximum'] = field.max if field.max

        if field.type == :array
          if field.of
            prop['items'] = { 'type' => TYPE_MAP.fetch(field.of, field.of.to_s) }
          elsif field.schema
            prop['items'] = field.schema.to_json_schema
          end
        end

        if field.format.is_a?(Symbol) && Formats::FORMATS.key?(field.format)
          prop['format'] = field.format.to_s
        elsif field.format.is_a?(Regexp)
          prop['pattern'] = field.format.source
        end

        prop
      end

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

      def validate_dependencies(data, result)
        @dependencies.each do |dep|
          dep[:when_field].each do |cond_field, expected|
            next unless data.key?(cond_field) && data[cond_field] == expected
            next if data.key?(dep[:field]) && !data[dep[:field]].nil?

            result.errors << "#{dep[:field]} is required when #{cond_field} is #{expected}"
          end
        end
      end

      def validate_exclusive_groups(data, result)
        @exclusive_groups.each do |group|
          present = group[:fields].select { |f| data.key?(f) && !data[f].nil? }
          if present.length > 1
            result.errors << "Only one of #{group[:fields].join(', ')} is allowed (#{group[:name]})"
          end
        end
      end
    end
  end
end
