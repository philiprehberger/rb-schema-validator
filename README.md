# philiprehberger-schema_validator

[![Tests](https://github.com/philiprehberger/rb-schema-validator/actions/workflows/ci.yml/badge.svg)](https://github.com/philiprehberger/rb-schema-validator/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/philiprehberger-schema_validator.svg)](https://rubygems.org/gems/philiprehberger-schema_validator)
[![License](https://img.shields.io/github/license/philiprehberger/rb-schema-validator)](LICENSE)

Lightweight schema validation for Ruby hashes with type checking and coercion

## Requirements

- Ruby >= 3.1

## Installation

Add to your Gemfile:

```ruby
gem "philiprehberger-schema_validator"
```

Or install directly:

```bash
gem install philiprehberger-schema_validator
```

## Usage

### Define a Schema

```ruby
require "philiprehberger/schema_validator"

schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
  float :score, required: false, default: 0.0
  boolean :active
  array :tags, required: false
  hash_field :metadata, required: false
end
```

### Validate Data

```ruby
result = schema.validate({ name: "Alice", age: 30, active: true })

if result.valid?
  puts "Data is valid!"
else
  puts result.errors
end
```

### Raise on Invalid Data

```ruby
schema.validate!({ name: "Alice" })
# => raises Philiprehberger::SchemaValidator::ValidationError
```

### Type Coercion

Values are automatically coerced to the declared type when possible:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :count
  boolean :enabled
end

result = schema.validate({ count: "123", enabled: "true" })
result.valid? # => true
```

### Validation Options

#### `format:` — Regex Pattern Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :email, format: /\A[^@\s]+@[^@\s]+\z/
end
```

#### Format Presets

Use built-in format presets instead of writing regex patterns:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :email, format: :email
  string :website, format: :url
  string :id, format: :uuid
  string :created_at, format: :iso8601
  string :phone, format: :phone
end
```

Available presets:

| Preset     | Matches                                          |
|------------|--------------------------------------------------|
| `:email`   | Basic email format (`user@domain.tld`)           |
| `:url`     | HTTP/HTTPS URLs                                  |
| `:uuid`    | UUID v4 format                                   |
| `:iso8601` | ISO 8601 date and datetime                       |
| `:phone`   | International phone numbers                      |

Both symbol presets and `Regexp` values are supported for `format:`.

#### `in:` — Allowlist Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :role, in: %w[admin user guest]
end
```

#### `min:` / `max:` — Numeric Range Validation

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :age, min: 0, max: 150
  float :score, min: 0.0, max: 100.0
end
```

### Nested Schema Validation

Validate objects within objects using the `nested` DSL method:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name, required: true
  nested :address, required: true do
    string :city, required: true
    string :zip, required: true
  end
end

result = schema.validate({ name: "Alice", address: { city: "Vienna" } })
result.errors # => ["address.zip is required"]
```

Nested schemas support all the same field types and options. Nesting can go arbitrarily deep:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  nested :config, required: true do
    nested :database, required: true do
      string :host, required: true
      integer :port, required: true
    end
  end
end
```

### Array Element Validation

Validate the type of each element in an array with `of:`:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  array :tags, of: :string
  array :scores, of: :integer
end

result = schema.validate({ tags: ["a", "b"], scores: [1, "bad", 3] })
result.errors # => ["scores[1] must be a integer"]
```

Validate arrays of objects with `schema:`:

```ruby
address_schema = Philiprehberger::SchemaValidator.define do
  string :city, required: true
  string :zip, required: true
end

schema = Philiprehberger::SchemaValidator.define do
  array :addresses, schema: address_schema
end

result = schema.validate({ addresses: [{ city: "Vienna" }] })
result.errors # => ["addresses[0].zip is required"]
```

### Cross-Field Validation

Add schema-level validation blocks for relational checks between fields:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer :min_age, required: false
  integer :max_age, required: false

  validate do |data, errors|
    if data[:min_age] && data[:max_age] && data[:min_age] > data[:max_age]
      errors << "min_age must be less than or equal to max_age"
    end
  end
end
```

Multiple `validate` blocks can be defined on the same schema.

### Schema Composition

Combine and extend schemas using `merge`:

```ruby
base = Philiprehberger::SchemaValidator.define do
  string :name, required: true
end

extended = base.merge do
  integer :age, required: false
  string :email, required: true
end

extended.fields # => [:name, :age, :email]
```

The original schema is not modified. Nested schemas and cross-field validators are preserved in the merged schema.

### Schema Introspection

```ruby
schema = Philiprehberger::SchemaValidator.define do
  string :name
  integer :age
end

schema.fields # => [:name, :age]
```

### Custom Validation

Pass a block to any field definition for custom validation. Return a string to indicate an error:

```ruby
schema = Philiprehberger::SchemaValidator.define do
  integer(:age) { |v| "must be positive" if v.negative? }
  string(:email) { |v| "must contain @" unless v.include?("@") }
end
```

## Supported Types

| DSL Method   | Ruby Type | Coerces From       |
|-------------|-----------|-------------------|
| `string`    | String    | any (via `to_s`)  |
| `integer`   | Integer   | String            |
| `float`     | Float     | String            |
| `boolean`   | Boolean   | String (true/false/yes/no/1/0/on/off) |
| `array`     | Array     | -                 |
| `hash_field`| Hash      | -                 |

## API

### `Philiprehberger::SchemaValidator.define(&block)` -> `Schema`

Creates a new schema using the DSL block.

### `Schema#fields` -> `Array<Symbol>`

Returns the list of defined field names.

### `Schema#validate(data)` -> `Result`

Validates a hash against the schema. Returns a `Result` object.

### `Schema#validate!(data)` -> `Result`

Validates and raises `ValidationError` if invalid.

### `Schema#merge(&block)` -> `Schema`

Creates a new schema combining the current schema with additional definitions from the block.

### `Result#valid?` -> `Boolean`

Returns `true` if there are no errors.

### `Result#errors` -> `Array<String>`

Array of error message strings.


## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
