# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    module Constraints
      private

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

          field.schema.validate(elem).errors.each do |err|
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
