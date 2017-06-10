# frozen_string_literal: true

module Philiprehberger
  module SchemaValidator
    module Formats
      FORMATS = {
        email: /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/,
        url: %r{\Ahttps?://[^\s]+\z},
        uuid: /\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i,
        iso8601: /\A\d{4}-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2}(.\d+)?(Z|[+-]\d{2}:\d{2})?)?\z/,
        phone: /\A\+?[0-9\s\-().]{7,}\z/
      }.freeze
    end
  end
end
