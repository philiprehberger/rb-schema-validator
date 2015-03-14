# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    module Coercer
      BOOLEAN_TRUE = %w[true 1 yes on].freeze
      BOOLEAN_FALSE = %w[false 0 no off].freeze

      def self.coerce(value, type)
        return value if value.nil?

        send(:"coerce_#{type}", value)
      end

      def self.coerce_string(value)
        value.to_s
      end

      def self.coerce_integer(value)
        Integer(value)
      rescue ArgumentError, TypeError
        nil
      end

      def self.coerce_float(value)
        Float(value)
      rescue ArgumentError, TypeError
        nil
      end

      def self.coerce_boolean(value)
        return value if [true, false].include?(value)

        str = value.to_s.downcase
        return true if BOOLEAN_TRUE.include?(str)

        return false if BOOLEAN_FALSE.include?(str)

        nil
      end

      def self.coerce_array(value)
        value if value.is_a?(Array)
      end

      def self.coerce_hash(value)
        value if value.is_a?(Hash)
      end

      private_class_method :coerce_string, :coerce_integer, :coerce_float,
                           :coerce_boolean, :coerce_array, :coerce_hash
    end
  end
end
