# frozen_string_literal: true

require "spec_helper"

RSpec.describe Philiprehberger::SchemaValidator do
  describe ".define" do
    it "returns a Schema instance" do
      schema = described_class.define { string :name }
      expect(schema).to be_a(Philiprehberger::SchemaValidator::Schema)
    end
  end

  describe "validation" do
    subject(:schema) do
      described_class.define do
        string :name
        integer :age
        boolean :active, default: true
      end
    end

    it "passes with valid data" do
      result = schema.validate({ name: "Alice", age: 30 })
      expect(result).to be_valid
      expect(result.errors).to be_empty
    end

    it "fails when a required field is missing" do
      result = schema.validate({ name: "Alice" })
      expect(result).not_to be_valid
      expect(result.errors).to include("age is required")
    end

    it "fails when a field has the wrong type" do
      result = schema.validate({ name: "Alice", age: "not_a_number" })
      expect(result).not_to be_valid
      expect(result.errors).to include("age must be integer")
    end
  end

  describe "type coercion" do
    subject(:schema) do
      described_class.define do
        integer :count
        float :ratio
        boolean :enabled
      end
    end

    it "coerces string to integer" do
      result = schema.validate({ count: "123", ratio: 1.5, enabled: true })
      expect(result).to be_valid
    end

    it "coerces string to float" do
      result = schema.validate({ count: 1, ratio: "3.14", enabled: true })
      expect(result).to be_valid
    end

    it "coerces string to boolean" do
      result = schema.validate({ count: 1, ratio: 1.0, enabled: "true" })
      expect(result).to be_valid
    end
  end

  describe "default values" do
    subject(:schema) do
      described_class.define do
        string :name
        string :role, required: false, default: "user"
      end
    end

    it "applies default when field is absent" do
      result = schema.validate({ name: "Alice" })
      expect(result).to be_valid
    end
  end

  describe "optional fields" do
    subject(:schema) do
      described_class.define do
        string :name
        string :nickname, required: false
      end
    end

    it "passes when optional field is absent" do
      result = schema.validate({ name: "Alice" })
      expect(result).to be_valid
    end
  end

  describe "validate!" do
    subject(:schema) do
      described_class.define { string :name }
    end

    it "raises ValidationError on invalid data" do
      expect { schema.validate!({}) }.to raise_error(
        Philiprehberger::SchemaValidator::ValidationError, "name is required"
      )
    end

    it "returns Result on valid data" do
      result = schema.validate!({ name: "Alice" })
      expect(result).to be_valid
    end
  end

  describe "custom validation" do
    subject(:schema) do
      described_class.define do
        integer(:age) { |v| "must be positive" if v.negative? }
      end
    end

    it "passes custom validation" do
      result = schema.validate({ age: 25 })
      expect(result).to be_valid
    end

    it "fails custom validation" do
      result = schema.validate({ age: -1 })
      expect(result).not_to be_valid
      expect(result.errors).to include("age must be positive")
    end
  end

  describe "array and hash types" do
    subject(:schema) do
      described_class.define do
        array :tags
        hash_field :metadata
      end
    end

    it "passes with correct types" do
      result = schema.validate({ tags: %w[a b], metadata: { key: "val" } })
      expect(result).to be_valid
    end

    it "fails with wrong types" do
      result = schema.validate({ tags: "not_array", metadata: "not_hash" })
      expect(result).not_to be_valid
      expect(result.errors).to include("tags must be array")
      expect(result.errors).to include("metadata must be hash")
    end
  end
end
