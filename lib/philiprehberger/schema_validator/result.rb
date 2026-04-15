# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    class Result
      attr_reader :errors

      def initialize(errors: [])
        @errors = errors
      end

      def valid?
        @errors.empty?
      end

      # Number of errors in the result
      #
      # @return [Integer]
      def error_count
        @errors.length
      end

      # Structured hash representation of the result
      #
      # @return [Hash{Symbol => Object}]
      def to_h
        { valid: valid?, errors: @errors.dup, error_count: error_count }
      end

      # Group error messages by the leading field name (e.g. "address.zip" => "address")
      #
      # @return [Hash{String => Array<String>}]
      def errors_by_field
        @errors.each_with_object({}) do |err, acc|
          field = err.split(/[\s.]/, 2).first.to_s
          (acc[field] ||= []) << err
        end
      end
    end
  end
end
