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
    end
  end
end
