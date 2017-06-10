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

  describe "fields accessor" do
    subject(:schema) do
      described_class.define do
        string :name
        integer :age
        boolean :active
      end
    end

    it "returns field names" do
      expect(schema.fields).to eq(%i[name age active])
    end
  end

  describe "format validation" do
    subject(:schema) do
      described_class.define do
        string :email, format: /\A[^@\s]+@[^@\s]+\z/
      end
    end

    it "passes when value matches format" do
      result = schema.validate({ email: "alice@example.com" })
      expect(result).to be_valid
    end

    it "fails when value does not match format" do
      result = schema.validate({ email: "not-an-email" })
      expect(result).not_to be_valid
      expect(result.errors).to include("email does not match expected format")
    end
  end

  describe "in validation" do
    subject(:schema) do
      described_class.define do
        string :role, in: %w[admin user guest]
      end
    end

    it "passes when value is in the allowlist" do
      result = schema.validate({ role: "admin" })
      expect(result).to be_valid
    end

    it "fails when value is not in the allowlist" do
      result = schema.validate({ role: "superuser" })
      expect(result).not_to be_valid
      expect(result.errors).to include("role must be one of: admin, user, guest")
    end
  end

  describe "min/max validation" do
    subject(:schema) do
      described_class.define do
        integer :age, min: 0, max: 150
        float :score, min: 0.0, max: 100.0
      end
    end

    it "passes when values are within range" do
      result = schema.validate({ age: 25, score: 85.5 })
      expect(result).to be_valid
    end

    it "fails when integer is below min" do
      result = schema.validate({ age: -1, score: 50.0 })
      expect(result).not_to be_valid
      expect(result.errors).to include("age must be >= 0")
    end

    it "fails when integer is above max" do
      result = schema.validate({ age: 200, score: 50.0 })
      expect(result).not_to be_valid
      expect(result.errors).to include("age must be <= 150")
    end

    it "fails when float is below min" do
      result = schema.validate({ age: 25, score: -1.0 })
      expect(result).not_to be_valid
      expect(result.errors).to include("score must be >= 0.0")
    end

    it "fails when float is above max" do
      result = schema.validate({ age: 25, score: 101.0 })
      expect(result).not_to be_valid
      expect(result.errors).to include("score must be <= 100.0")
    end
  end

  describe "coerce_boolean fix" do
    subject(:schema) do
      described_class.define do
        boolean :flag
      end
    end

    it "returns nil for unrecognized boolean values" do
      result = schema.validate({ flag: "maybe" })
      expect(result).not_to be_valid
      expect(result.errors).to include("flag must be boolean")
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

  describe "nested schema validation" do
    context "with required nested schema" do
      subject(:schema) do
        described_class.define do
          string :name, required: true
          nested :address, required: true do
            string :city, required: true
            string :zip, required: true
          end
        end
      end

      it "passes with valid nested data" do
        result = schema.validate({ name: "Alice", address: { city: "Vienna", zip: "1010" } })
        expect(result).to be_valid
      end

      it "fails when required nested field is missing" do
        result = schema.validate({ name: "Alice" })
        expect(result).not_to be_valid
        expect(result.errors).to include("address is required")
      end

      it "fails when nested field is not a hash" do
        result = schema.validate({ name: "Alice", address: "not a hash" })
        expect(result).not_to be_valid
        expect(result.errors).to include("address must be a hash")
      end

      it "prefixes nested errors with parent name" do
        result = schema.validate({ name: "Alice", address: { city: "Vienna" } })
        expect(result).not_to be_valid
        expect(result.errors).to include("address.zip is required")
      end

      it "reports multiple nested errors" do
        result = schema.validate({ name: "Alice", address: {} })
        expect(result).not_to be_valid
        expect(result.errors).to include("address.city is required")
        expect(result.errors).to include("address.zip is required")
      end
    end

    context "with optional nested schema" do
      subject(:schema) do
        described_class.define do
          string :name
          nested :address do
            string :city, required: true
          end
        end
      end

      it "passes when optional nested field is absent" do
        result = schema.validate({ name: "Alice" })
        expect(result).to be_valid
      end

      it "validates nested data when present" do
        result = schema.validate({ name: "Alice", address: {} })
        expect(result).not_to be_valid
        expect(result.errors).to include("address.city is required")
      end
    end

    context "with deeply nested schemas" do
      subject(:schema) do
        described_class.define do
          nested :level1, required: true do
            nested :level2, required: true do
              string :value, required: true
            end
          end
        end
      end

      it "validates deeply nested data" do
        result = schema.validate({ level1: { level2: { value: "hello" } } })
        expect(result).to be_valid
      end

      it "prefixes deeply nested errors" do
        result = schema.validate({ level1: { level2: {} } })
        expect(result).not_to be_valid
        expect(result.errors).to include("level1.level2.value is required")
      end
    end
  end

  describe "array element validation" do
    context "with of: type" do
      subject(:schema) do
        described_class.define do
          array :tags, of: :string
          array :scores, of: :integer
        end
      end

      it "passes when all elements match the type" do
        result = schema.validate({ tags: %w[a b c], scores: [1, 2, 3] })
        expect(result).to be_valid
      end

      it "fails when an element does not match the type" do
        result = schema.validate({ tags: ["a", 123, "c"], scores: [1, "not_int", 3] })
        expect(result).not_to be_valid
        expect(result.errors).to include("scores[1] must be a integer")
      end

      it "reports errors with correct index" do
        result = schema.validate({ tags: %w[a b c], scores: [1, 2, "bad"] })
        expect(result).not_to be_valid
        expect(result.errors).to include("scores[2] must be a integer")
      end

      it "passes with an empty array" do
        result = schema.validate({ tags: [], scores: [] })
        expect(result).to be_valid
      end
    end

    context "with of: :boolean" do
      subject(:schema) do
        described_class.define do
          array :flags, of: :boolean
        end
      end

      it "passes with boolean elements" do
        result = schema.validate({ flags: [true, false, true] })
        expect(result).to be_valid
      end

      it "fails with non-boolean elements" do
        result = schema.validate({ flags: [true, "maybe", false] })
        expect(result).not_to be_valid
        expect(result.errors).to include("flags[1] must be a boolean")
      end
    end

    context "with schema: for array of objects" do
      let(:address_schema) do
        described_class.define do
          string :city, required: true
          string :zip, required: true
        end
      end

      subject(:schema) do
        addr = address_schema
        described_class.define do
          array :addresses, schema: addr
        end
      end

      it "passes with valid objects" do
        result = schema.validate({ addresses: [{ city: "Vienna", zip: "1010" }, { city: "Berlin", zip: "10115" }] })
        expect(result).to be_valid
      end

      it "fails when an element is not a hash" do
        result = schema.validate({ addresses: ["not a hash"] })
        expect(result).not_to be_valid
        expect(result.errors).to include("addresses[0] must be a hash")
      end

      it "fails when an element is missing required fields" do
        result = schema.validate({ addresses: [{ city: "Vienna" }] })
        expect(result).not_to be_valid
        expect(result.errors).to include("addresses[0].zip is required")
      end

      it "reports errors for multiple elements" do
        result = schema.validate({ addresses: [{}, { city: "Berlin" }] })
        expect(result).not_to be_valid
        expect(result.errors).to include("addresses[0].city is required")
        expect(result.errors).to include("addresses[0].zip is required")
        expect(result.errors).to include("addresses[1].zip is required")
      end
    end
  end

  describe "format presets" do
    describe ":email" do
      subject(:schema) do
        described_class.define do
          string :email, format: :email
        end
      end

      it "passes with valid email" do
        result = schema.validate({ email: "alice@example.com" })
        expect(result).to be_valid
      end

      it "fails with invalid email" do
        result = schema.validate({ email: "not-an-email" })
        expect(result).not_to be_valid
      end

      it "fails with email missing domain extension" do
        result = schema.validate({ email: "alice@example" })
        expect(result).not_to be_valid
      end
    end

    describe ":url" do
      subject(:schema) do
        described_class.define do
          string :website, format: :url
        end
      end

      it "passes with http URL" do
        result = schema.validate({ website: "http://example.com" })
        expect(result).to be_valid
      end

      it "passes with https URL" do
        result = schema.validate({ website: "https://example.com/path?q=1" })
        expect(result).to be_valid
      end

      it "fails with non-URL" do
        result = schema.validate({ website: "not-a-url" })
        expect(result).not_to be_valid
      end
    end

    describe ":uuid" do
      subject(:schema) do
        described_class.define do
          string :id, format: :uuid
        end
      end

      it "passes with valid UUID v4" do
        result = schema.validate({ id: "550e8400-e29b-41d4-a716-446655440000" })
        expect(result).to be_valid
      end

      it "fails with invalid UUID" do
        result = schema.validate({ id: "not-a-uuid" })
        expect(result).not_to be_valid
      end
    end

    describe ":iso8601" do
      subject(:schema) do
        described_class.define do
          string :date, format: :iso8601
        end
      end

      it "passes with date only" do
        result = schema.validate({ date: "2026-03-16" })
        expect(result).to be_valid
      end

      it "passes with datetime and Z" do
        result = schema.validate({ date: "2026-03-16T10:30:00Z" })
        expect(result).to be_valid
      end

      it "passes with datetime and offset" do
        result = schema.validate({ date: "2026-03-16T10:30:00+01:00" })
        expect(result).to be_valid
      end

      it "fails with invalid date" do
        result = schema.validate({ date: "March 16, 2026" })
        expect(result).not_to be_valid
      end
    end

    describe ":phone" do
      subject(:schema) do
        described_class.define do
          string :phone, format: :phone
        end
      end

      it "passes with international format" do
        result = schema.validate({ phone: "+1 555-123-4567" })
        expect(result).to be_valid
      end

      it "passes with parentheses format" do
        result = schema.validate({ phone: "(555) 123-4567" })
        expect(result).to be_valid
      end

      it "fails with too short" do
        result = schema.validate({ phone: "123" })
        expect(result).not_to be_valid
      end
    end

    it "still works with Regexp format" do
      schema = described_class.define do
        string :code, format: /\A[A-Z]{3}\z/
      end

      expect(schema.validate({ code: "ABC" })).to be_valid
      expect(schema.validate({ code: "abc" })).not_to be_valid
    end

    it "raises ArgumentError for unknown preset" do
      schema = described_class.define do
        string :field, format: :nonexistent
      end

      expect { schema.validate({ field: "value" }) }.to raise_error(ArgumentError, /unknown format preset/)
    end
  end

  describe "cross-field validation" do
    subject(:schema) do
      described_class.define do
        integer :min_age, required: false
        integer :max_age, required: false

        validate do |data, errors|
          if data[:min_age] && data[:max_age] && data[:min_age] > data[:max_age]
            errors << "min_age must be less than or equal to max_age"
          end
        end
      end
    end

    it "passes when cross-field constraint is satisfied" do
      result = schema.validate({ min_age: 18, max_age: 65 })
      expect(result).to be_valid
    end

    it "fails when cross-field constraint is violated" do
      result = schema.validate({ min_age: 65, max_age: 18 })
      expect(result).not_to be_valid
      expect(result.errors).to include("min_age must be less than or equal to max_age")
    end

    it "passes when optional fields are absent" do
      result = schema.validate({})
      expect(result).to be_valid
    end

    it "supports multiple cross-field validators" do
      schema = described_class.define do
        integer :start_val, required: false
        integer :end_val, required: false
        string :name, required: false

        validate do |data, errors|
          if data[:start_val] && data[:end_val] && data[:start_val] > data[:end_val]
            errors << "start_val must be <= end_val"
          end
        end

        validate do |data, errors|
          errors << "name is too short" if data[:name] && data[:name].length < 2
        end
      end

      result = schema.validate({ start_val: 10, end_val: 5, name: "A" })
      expect(result).not_to be_valid
      expect(result.errors).to include("start_val must be <= end_val")
      expect(result.errors).to include("name is too short")
    end
  end

  describe "schema composition via merge" do
    let(:base) do
      described_class.define do
        string :name, required: true
        integer :age, required: false
      end
    end

    it "creates a new schema with additional fields" do
      extended = base.merge do
        string :email, required: true
      end

      result = extended.validate({ name: "Alice", email: "alice@example.com" })
      expect(result).to be_valid
    end

    it "includes base schema fields" do
      extended = base.merge do
        string :email
      end

      result = extended.validate({ email: "alice@example.com" })
      expect(result).not_to be_valid
      expect(result.errors).to include("name is required")
    end

    it "does not modify the original schema" do
      base.merge do
        string :email
      end

      expect(base.fields).to eq(%i[name age])
    end

    it "preserves cross-field validators" do
      with_validator = described_class.define do
        integer :min_val, required: false
        integer :max_val, required: false

        validate do |data, errors|
          if data[:min_val] && data[:max_val] && data[:min_val] > data[:max_val]
            errors << "min_val must be <= max_val"
          end
        end
      end

      extended = with_validator.merge do
        string :label, required: false
      end

      result = extended.validate({ min_val: 10, max_val: 5 })
      expect(result).not_to be_valid
      expect(result.errors).to include("min_val must be <= max_val")
    end

    it "preserves nested schemas" do
      with_nested = described_class.define do
        nested :address, required: true do
          string :city, required: true
        end
      end

      extended = with_nested.merge do
        string :name
      end

      result = extended.validate({ name: "Alice" })
      expect(result).not_to be_valid
      expect(result.errors).to include("address is required")
    end

    it "can add new fields in merged schema" do
      extended = base.merge do
        float :score, required: false
      end

      expect(extended.fields).to eq(%i[name age score])
    end
  end
end
